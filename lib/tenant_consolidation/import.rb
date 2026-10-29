# frozen_string_literal: true

module TenantConsolidation
  # Writes a group's dump into the public schema as the group plans it.
  #
  #   preflight!        refuses before anything is written, naming every problem
  #   import_rows!      all sites' rows in one transaction → old→new id map
  #   transfer_assets!  each upload in its own transaction, after the rows commit
  #
  # A failure after the rows commit leaves them in public; recovery is
  # rollback[group] and a fresh run, since the tenant source is never touched.
  class Import
    class Invalid < StandardError; end

    # A row of a model the group lists in SHARED is written once for every site
    # holding the same columns, and belongs to no site; the first site's copy, its
    # timestamps included, is the one kept.
    SHARED_IGNORED = %w[created_at updated_at].freeze

    def self.shared_key(row) = [ row.model, row.attributes.except(*SHARED_IGNORED) ]

    def initialize(group, dump)
      @group = group
      @dump = dump
      @pending_assets = []
    end

    def preflight!
      problems = public_problems + site_problems + plan_problems
      raise Invalid, "Refusing to import:\n#{problems.map { |p| "  - #{p}" }.join("\n")}" if problems.any?
    end

    # { tenant_name => { dumped model => { old_id => new_id } } } — a row the plan
    # writes as another model maps to the row it became.
    def import_rows!
      Apartment::Tenant.switch("public") do
        ActiveRecord::Base.transaction do
          plans.to_h { |plan| [ plan.site.tenant_name, import_site(plan) ] }
        end
      end
    end

    def transfer_assets!
      Apartment::Tenant.switch("public") { Assets.transfer_assets!(@pending_assets) }
    end

    def plans
      @plans ||= @dump.sites.map { |site| @group.plan(site) }
    end

    def summary
      plans.map do |plan|
        line = "#{plan.site.tenant_name}: " + @group::TARGETS.map { |model| "#{plan.rows_of(model).size} #{model}" }.join(", ")
        skipped = plan.skipped.reject { |_model, rows| rows.empty? }.map do |model, rows|
          "skipped #{model} #{rows.map { |row| "##{row.id}" }.join(' ')} (left for review)"
        end
        [ line, *skipped ].join("; ")
      end + @group::SHARED.map { |model| "shared: #{shared_keys(model).size} #{model}" }
    end

    def shared_keys(model)
      plans.flat_map { |plan| plan.rows_of(model) }.map { |row| Import.shared_key(row) }.uniq
    end

    # What verify reads to find each dumped row's public counterpart, and what the
    # rewrite of embedded URLs can later resolve an old id against.
    def id_map_json(ids)
      JSON.pretty_generate(
        "format" => Dump::FORMAT,
        "group" => @dump.group,
        "dump_created_at" => @dump.created_at.utc.iso8601(6),
        "sites" => ids,
        "skipped" => plans.to_h do |plan|
          [ plan.site.tenant_name, plan.skipped.transform_values { |rows| rows.map(&:id) } ]
        end,
        "stand_ins" => plans.to_h do |plan|
          [ plan.site.tenant_name, plan.stand_ins.map { |stand_in| stand_in.to_h.transform_keys(&:to_s) } ]
        end
      )
    end

    private

    def import_site(plan)
      site = ::Site.find_by!(tenant_name: plan.site.tenant_name)
      ids = Hash.new { |hash, model| hash[model] = {} }

      ActsAsTenant.with_tenant(site) do
        plan.rows.each do |row|
          refs = row.refs.transform_values { |parent| parent && ids.fetch(parent.first).fetch(parent.last) }
          record = if @group::SHARED.include?(row.model)
            shared_records[Import.shared_key(row)] ||= write(row.model, row.attributes.merge(refs), nil)
          else
            write(row.model, row.attributes.merge(refs), site)
          end
          ids[row.source.first][row.source.last] = record.id
          queue_upload(record, row.upload)
        end
      end

      ids
    end

    def shared_records
      @shared_records ||= {}
    end

    def write(model_name, attributes, site)
      record = model_name.constantize.new
      Records.assign_raw_attributes(record, attributes)
      record.site_id = site&.id
      record.save!(validate: false)
      Records.verify_written_as_planned(attributes, record, model_name)
      record
    end

    def queue_upload(record, upload)
      return unless upload

      @pending_assets << { record: record, field: upload.field, attachment: :"#{upload.field}_attachment",
                           url: upload.url, size: upload.size }
    end

    def public_problems
      problems = []
      in_public = @group::TARGETS & Apartment.excluded_models.map(&:to_s)
      problems << "#{in_public.join(', ')} already served from the public schema" if in_public.any?

      Apartment::Tenant.switch("public") do
        @group::TARGETS.map(&:constantize).each do |model|
          count = model.unscoped.count
          next unless count.positive?

          problems << "public #{model.table_name} already holds #{count} row(s) — run rollback[#{@group::NAME}] first"
        end

        ActiveStorage::Attachment.where(record_type: @group::TARGETS).group(:record_type).count.each do |type, count|
          problems << "#{count} ActiveStorage attachment(s) already sit on #{type} ids"
        end
      end
      problems
    end

    def site_problems
      known = ::Site.pluck(:tenant_name)
      @dump.sites.map(&:tenant_name).reject { |name| known.include?(name) }
           .map { |name| "no Site here for dumped tenant #{name}" }
    end

    def plan_problems
      plans.flat_map do |plan|
        plan.rows.select { |row| row.upload&.missing? }.map do |row|
          "#{plan.site.tenant_name} #{row.source.join('#')} #{row.upload.field} source is missing (#{row.upload.path})"
        end
      end
    rescue Plan::Invalid => e
      [ e.message ]
    end
  end
end
