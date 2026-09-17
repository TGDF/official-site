# frozen_string_literal: true

module TenantConsolidation
  module SponsorGroup
    # Writes a sponsor dump into the public schema as its Transform plans it.
    #
    #   preflight!        refuses before anything is written, naming every problem
    #   import_rows!      all sites' rows in one transaction → old→new id map
    #   transfer_assets!  each logo in its own transaction, after the rows commit
    #
    # A failure after the rows commit leaves them in public; recovery is
    # rollback[sponsor] and a fresh run, since the tenant source is never touched.
    class Import
      class Invalid < StandardError; end

      def initialize(dump)
        @dump = dump
        @pending_assets = []
      end

      def preflight!
        problems = public_problems + site_problems + plan_problems
        raise Invalid, "Refusing to import:\n#{problems.map { |p| "  - #{p}" }.join("\n")}" if problems.any?
      end

      # { tenant_name => { "SponsorLevel" | "PartnerType" | "Sponsor" | "Partner" => { old_id => new_id } } }
      # — a PartnerType maps to the SponsorLevel it became, a Partner to its Sponsor.
      def import_rows!
        Apartment::Tenant.switch("public") do
          ActiveRecord::Base.transaction do
            transforms.to_h { |transform| [ transform.site.tenant_name, import_site(transform) ] }
          end
        end
      end

      def transfer_assets!
        Apartment::Tenant.switch("public") { Assets.transfer_assets!(@pending_assets) }
      end

      def transforms
        @transforms ||= @dump.sites.map { |site| Transform.new(site) }
      end

      def summary
        transforms.map do |transform|
          line = "#{transform.site.tenant_name}: #{transform.levels.size} level(s), " \
                 "#{transform.sponsors.size} sponsor(s)"
          skipped = transform.skipped_partners.map { |row| "##{row.id}" }
          skipped.any? ? "#{line}; skipped Partner #{skipped.join(' ')} (name held in the site)" : line
        end
      end

      # What verify reads to find each dumped row's public counterpart, and what the
      # rewrite of embedded URLs can later resolve an old id against.
      def id_map_json(ids)
        JSON.pretty_generate(
          "format" => Dump::FORMAT,
          "group" => @dump.group,
          "dump_created_at" => @dump.created_at.utc.iso8601(6),
          "sites" => ids,
          "skipped" => transforms.to_h do |transform|
            [ transform.site.tenant_name, { "Partner" => transform.skipped_partners.map(&:id) } ]
          end
        )
      end

      private

      def import_site(transform)
        site = ::Site.find_by!(tenant_name: transform.site.tenant_name)
        ids = Hash.new { |hash, model| hash[model] = {} }

        ActsAsTenant.with_tenant(site) do
          transform.levels.each do |row|
            level = write(::SponsorLevel, "SponsorLevel", row.attributes, site)
            ids[row.source.first][row.source.last] = level.id
          end

          transform.sponsors.each do |row|
            level_id = row.level && ids.fetch(row.level.first).fetch(row.level.last)
            sponsor = write(::Sponsor, "Sponsor", row.attributes.merge("level_id" => level_id), site)
            ids[row.source.first][row.source.last] = sponsor.id
            queue_logo(sponsor, row.upload)
          end
        end

        ids
      end

      def write(model_class, model_name, attributes, site)
        record = model_class.new
        Records.assign_raw_attributes(record, attributes)
        record.site_id = site.id
        record.save!(validate: false)
        Records.verify_translations_preserved(attributes, record, model_name)
        record
      end

      def queue_logo(sponsor, upload)
        return unless upload

        @pending_assets << { record: sponsor, field: upload.field, attachment: :logo_attachment,
                            url: upload.url, size: upload.size }
      end

      def public_problems
        problems = []
        in_public = %w[SponsorLevel Sponsor] & Apartment.excluded_models.map(&:to_s)
        problems << "#{in_public.join(', ')} already served from the public schema" if in_public.any?

        Apartment::Tenant.switch("public") do
          [ ::SponsorLevel, ::Sponsor ].each do |model|
            count = model.unscoped.count
            problems << "public #{model.table_name} already holds #{count} row(s) — run rollback[sponsor] first" if count.positive?
          end

          leftover = ActiveStorage::Attachment.where(record_type: "Sponsor").count
          problems << "#{leftover} ActiveStorage attachment(s) already sit on Sponsor ids" if leftover.positive?
        end
        problems
      end

      def site_problems
        known = ::Site.pluck(:tenant_name)
        @dump.sites.map(&:tenant_name).reject { |name| known.include?(name) }
             .map { |name| "no Site here for dumped tenant #{name}" }
      end

      def plan_problems
        transforms.flat_map do |transform|
          transform.sponsors.select { |row| row.upload&.missing? }.map do |row|
            "#{transform.site.tenant_name} #{row.source.join('#')} logo source is missing (#{row.upload.path})"
          end
        end
      rescue Transform::Invalid => e
        [ e.message ]
      end
    end
  end
end
