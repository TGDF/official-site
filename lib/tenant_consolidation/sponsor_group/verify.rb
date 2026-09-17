# frozen_string_literal: true

module TenantConsolidation
  module SponsorGroup
    # Checks the public schema against what the import was meant to write — the dump
    # replanned by Transform — row by row, through the id map migrate wrote:
    #
    #   dump.json ─ Transform ─▶ planned row ─ id_map.json ─▶ public row
    #                                  │                          │
    #                                  └──── same site, same columns, same locales,
    #                                        right level, logo at the source size and readable
    #
    # plus, per site, no public row the plan does not account for. It reads only, so
    # it can run as often as wanted — before the switch deploy and after it.
    class Verify
      # One site being checked: where its rows must sit, and its part of the id map.
      Context = Data.define(:tenant_name, :site, :ids)

      def initialize(dump, id_map)
        @dump = dump
        @id_map = id_map
      end

      def problems
        Apartment::Tenant.switch("public") do
          @dump.sites.flat_map { |site| site_problems(Transform.new(site)) }
        end
      end

      private

      def site_problems(transform)
        tenant_name = transform.site.tenant_name
        site = ::Site.find_by(tenant_name: tenant_name)
        return [ "#{tenant_name}: no Site here" ] unless site

        ctx = Context.new(tenant_name, site, @id_map.dig("sites", tenant_name) || {})
        transform.levels.flat_map { |row| row_problems(::SponsorLevel, row, ctx) } +
          transform.sponsors.flat_map { |row| sponsor_problems(row, ctx) } +
          count_problem(::SponsorLevel, transform.levels.size, ctx) +
          count_problem(::Sponsor, transform.sponsors.size, ctx)
      end

      # Attaching a logo touches its record (ActiveStorage.touch_attachment_records), so
      # for a sponsor that carried one, updated_at is the moment of the move.
      def sponsor_problems(row, ctx)
        problems = row_problems(::Sponsor, row, ctx, skip: row.upload ? %w[updated_at] : [])
        sponsor = find(::Sponsor, row, ctx)
        return problems unless sponsor

        expected_level = row.level && ctx.ids.dig(*stringified(row.level))
        unless sponsor.level_id == expected_level
          problems << "#{label(row, ctx)} is under level #{sponsor.level_id.inspect}, expected #{expected_level.inspect}"
        end
        problems + logo_problems(sponsor, row, ctx)
      end

      def row_problems(model_class, row, ctx, skip: [])
        record = find(model_class, row, ctx)
        return [ "#{label(row, ctx)} has no public #{model_class.name}" ] unless record

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

      def logo_problems(sponsor, row, ctx)
        return [] unless row.upload

        attachment = sponsor.logo_attachment
        return [ "#{label(row, ctx)} has no logo in ActiveStorage" ] unless attachment.attached?

        problems = []
        marker = row.attributes["logo"]
        problems << "#{label(row, ctx)} logo is #{attachment.filename}, expected #{marker}" unless attachment.filename.to_s == marker
        unless attachment.byte_size == row.upload.size
          problems << "#{label(row, ctx)} logo is #{attachment.byte_size} bytes, the source was #{row.upload.size}"
        end
        problems + readability_problems(attachment.blob, row, ctx)
      end

      # Analysis runs during migrate. An image vips cannot read still counts as
      # analyzed, only without the width and height a readable one carries.
      def readability_problems(blob, row, ctx)
        if !blob.analyzed?
          [ "#{label(row, ctx)} logo was never analyzed" ]
        elsif blob.metadata.values_at(:width, :height).any?(&:blank?)
          [ "#{label(row, ctx)} logo cannot be read as an image" ]
        else
          []
        end
      end

      def count_problem(model_class, planned, ctx)
        actual = model_class.unscoped.where(site_id: ctx.site.id).count
        return [] if actual == planned

        [ "#{ctx.tenant_name}: public holds #{actual} #{model_class.name} row(s), the plan has #{planned}" ]
      end

      def find(model_class, row, ctx)
        public_id = ctx.ids.dig(*stringified(row.source))
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
end
