# frozen_string_literal: true

module TenantConsolidation
  module SponsorGroup
    # What a sponsor dump holds and what the import will do with it, read before
    # anything is written: the rows per site, the files that cannot be fetched, the
    # partners the import will skip, and the labels it will correct.
    class Census
      Missing = Data.define(:tenant_name, :model, :id, :path)
      Duplicate = Data.define(:tenant_name, :partner_id, :name)
      LabelFix = Data.define(:tenant_name, :partner_type_id, :from, :to)

      def initialize(dump)
        @dump = dump
      end

      def missing_sources
        @dump.sites.flat_map do |site|
          UPLOADS.keys.flat_map do |model|
            site.rows(model).select { |row| row.upload&.missing? }
                .map { |row| Missing.new(site.tenant_name, model, row.id, row.upload.path) }
          end
        end
      end

      # Names are compared as the whole JSONB value, locales and all.
      def duplicate_names
        @dump.sites.flat_map do |site|
          sponsor_names = site.rows("Sponsor").map { |row| row.attributes["name"] }
          site.rows("Partner").select { |row| sponsor_names.include?(row.attributes["name"]) }
              .map { |row| Duplicate.new(site.tenant_name, row.id, row.attributes["name"]) }
        end
      end

      def label_fixes
        @dump.sites.flat_map do |site|
          site.rows("PartnerType").filter_map do |row|
            name = row.attributes["name"]
            fixed = SponsorGroup.level_name_for(site.tenant_name, name)
            LabelFix.new(site.tenant_name, row.id, name, fixed) unless fixed == name
          end
        end
      end

      # A consolidated model is the only one that may carry an ActiveStorage
      # attachment; one on a tenant-schema row was left by tooling or an aborted run,
      # and would sit on a public row with the same id once the group has moved.
      def leftover_attachments
        ActiveStorage::Attachment.where(record_type: UPLOADS.keys).group(:record_type).count
      end

      def report
        [
          counts_table,
          section("Logos whose source file is missing", missing_sources) do |m|
            "#{m.tenant_name} #{m.model}##{m.id} #{m.path}"
          end,
          section("Leftover ActiveStorage attachments on #{UPLOADS.keys.join('/')}",
                  leftover_attachments.to_a) { |type, count| "#{type}: #{count}" },
          section("Partners named like a Sponsor of the same site (skipped on import)",
                  duplicate_names) { |d| "#{d.tenant_name} Partner##{d.partner_id} #{d.name}" },
          section("PartnerType labels corrected on import", label_fixes) do |f|
            "#{f.tenant_name} PartnerType##{f.partner_type_id} #{f.from} → #{f.to}"
          end
        ].join("\n\n")
      end

      private

      def counts_table
        width = [ @dump.sites.map { |site| site.tenant_name.size }.max.to_i, 6 ].max
        header = "site".ljust(width) + MODELS.map { |m| m.rjust(14) }.join
        rows = @dump.counts.map do |tenant_name, counts|
          tenant_name.ljust(width) + MODELS.map { |m| counts.fetch(m, 0).to_s.rjust(14) }.join
        end
        [ "Sponsor group — #{@dump.sites.size} site(s)", header, *rows ].join("\n")
      end

      def section(title, items, &line)
        [ "#{title} (#{items.size})", *items.map { |item| "  #{line.call(item)}" } ].join("\n")
      end
    end
  end
end
