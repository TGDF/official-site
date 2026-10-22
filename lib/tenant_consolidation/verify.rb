# frozen_string_literal: true

module TenantConsolidation
  # Checks the public schema against what the import was meant to write — the dump
  # replanned by its group — row by row, through the id map migrate wrote:
  #
  #   dump.json ─ group.plan ─▶ planned row ─ id_map.json ─▶ public row
  #                                  │                          │
  #                                  └──── same site, same columns, same locales,
  #                                        right parents, upload at the source size and readable
  #
  # plus, per site, no public row the plan does not account for. It reads only, so
  # it can run as often as wanted — before the switch deploy and after it.
  class Verify
    # One site being checked: where its rows must sit, and its part of the id map.
    Context = Data.define(:tenant_name, :site, :ids)

    def initialize(group, dump, id_map)
      @group = group
      @dump = dump
      @id_map = id_map
    end

    def problems
      Apartment::Tenant.switch("public") do
        @dump.sites.flat_map { |site| site_problems(@group.plan(site)) }
      end
    end

    private

    def site_problems(plan)
      tenant_name = plan.site.tenant_name
      site = ::Site.find_by(tenant_name: tenant_name)
      return [ "#{tenant_name}: no Site here" ] unless site

      ctx = Context.new(tenant_name, site, @id_map.dig("sites", tenant_name) || {})
      plan.rows.flat_map { |row| row_problems(row, ctx) } +
        @group::TARGETS.flat_map { |model| count_problem(model.constantize, plan.rows_of(model).size, ctx) }
    end

    # Attaching an upload touches its record (ActiveStorage.touch_attachment_records),
    # so for a row that carried one, updated_at is the moment of the move.
    def row_problems(row, ctx)
      model_class = row.model.constantize
      record = find(model_class, row.source, ctx)
      return [ "#{label(row, ctx)} has no public #{model_class.name}" ] unless record

      column_problems(model_class, record, row, ctx, skip: row.upload ? %w[updated_at] : []) +
        ref_problems(record, row, ctx) +
        upload_problems(record, row, ctx)
    end

    def column_problems(model_class, record, row, ctx, skip:)
      problems = []
      unless record.site_id == ctx.site.id
        problems << "#{label(row, ctx)} belongs to site #{record.site_id}, expected #{ctx.site.id}"
      end
      (row.attributes.keys - skip).each do |column|
        expected = model_class.type_for_attribute(column).cast(row.attributes[column])
        actual = record[column]
        problems << "#{label(row, ctx)}.#{column} is #{actual.inspect}, expected #{expected.inspect}" unless actual == expected
      end
      problems
    end

    def ref_problems(record, row, ctx)
      row.refs.filter_map do |column, parent|
        expected = parent && ctx.ids.dig(*stringified(parent))
        next if record[column] == expected

        "#{label(row, ctx)} is under #{column.delete_suffix('_id')} #{record[column].inspect}, expected #{expected.inspect}"
      end
    end

    def upload_problems(record, row, ctx)
      upload = row.upload
      return [] unless upload

      attachment = record.public_send(:"#{upload.field}_attachment")
      return [ "#{label(row, ctx)} has no #{upload.field} in ActiveStorage" ] unless attachment.attached?

      problems = []
      marker = row.attributes[upload.field]
      unless attachment.filename.to_s == marker
        problems << "#{label(row, ctx)} #{upload.field} is #{attachment.filename}, expected #{marker}"
      end
      unless attachment.byte_size == upload.size
        problems << "#{label(row, ctx)} #{upload.field} is #{attachment.byte_size} bytes, the source was #{upload.size}"
      end
      problems + readability_problems(attachment.blob, upload.field, row, ctx)
    end

    # Analysis runs during migrate. An image vips cannot read still counts as
    # analyzed, only without the width and height a readable one carries.
    def readability_problems(blob, field, row, ctx)
      if !blob.analyzed?
        [ "#{label(row, ctx)} #{field} was never analyzed" ]
      elsif blob.metadata.values_at(:width, :height).any?(&:blank?)
        [ "#{label(row, ctx)} #{field} cannot be read as an image" ]
      else
        []
      end
    end

    def count_problem(model_class, planned, ctx)
      actual = model_class.unscoped.where(site_id: ctx.site.id).count
      return [] if actual == planned

      [ "#{ctx.tenant_name}: public holds #{actual} #{model_class.name} row(s), the plan has #{planned}" ]
    end

    def find(model_class, source, ctx)
      public_id = ctx.ids.dig(*stringified(source))
      public_id && model_class.unscoped.find_by(id: public_id)
    end

    def stringified(source)
      [ source.first, source.last.to_s ]
    end

    def label(row, ctx)
      "#{ctx.tenant_name} #{row.source.join('#')}"
    end
  end
end
