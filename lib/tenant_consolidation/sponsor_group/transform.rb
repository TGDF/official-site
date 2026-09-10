# frozen_string_literal: true

module TenantConsolidation
  module SponsorGroup
    # What one dumped site becomes in the public schema. It reads the dump and
    # nothing else, so the census can show the outcome before anything is written,
    # the import writes exactly this, and verify compares the public schema against it.
    #
    #   SponsorLevel ───────────────────────────────▶ level
    #   PartnerType ── same-site level of that name? ─ yes ─▶ (reuses it)
    #                                               └ no ──▶ level, 2023tgdf label fixed
    #   Sponsor ───────────────────────────────────▶ sponsor under its level
    #   Partner ── name taken in the site? ── yes ─▶ skipped, left for review
    #                                     └── no ──▶ sponsor under its type's level
    #
    # `source` is the dumped row a planned row comes from, as [model, id]; a sponsor's
    # `level` is the source of its level, which for a merged partner may be a PartnerType.
    class Transform
      LevelRow = Data.define(:source, :attributes)
      SponsorRow = Data.define(:source, :level, :attributes, :upload)
      LabelFix = Data.define(:partner_type_id, :from, :to)

      class Invalid < StandardError; end

      # Never carried over: the public row gets a fresh id and the importing site's id,
      # and a foreign key is re-pointed at the parent's new row.
      DROPPED = %w[id site_id level_id type_id].freeze

      attr_reader :site, :levels, :sponsors, :skipped_partners, :label_fixes

      def initialize(site)
        @site = site
        @levels = []
        @sponsors = []
        @skipped_partners = []
        @label_fixes = []
        @level_by_type = {}
        plan
      end

      private

      def plan
        plan_levels
        plan_partner_types
        plan_sponsors
        plan_partners
      end

      def plan_levels
        site.rows("SponsorLevel").each do |row|
          @levels << LevelRow.new([ "SponsorLevel", row.id ], carried(row))
        end
      end

      def plan_partner_types
        site.rows("PartnerType").each do |row|
          name = row.attributes["name"]
          fixed = SponsorGroup.level_name_for(site.tenant_name, name)
          @label_fixes << LabelFix.new(row.id, name, fixed) unless fixed == name

          @level_by_type[row.id] = existing_level_named(fixed) || begin
            @levels << LevelRow.new([ "PartnerType", row.id ], carried(row).merge("name" => fixed))
            [ "PartnerType", row.id ]
          end
        end
      end

      def existing_level_named(name)
        @levels.find { |level| level.source.first == "SponsorLevel" && level.attributes["name"] == name }&.source
      end

      def plan_sponsors
        level_ids = site.rows("SponsorLevel").map(&:id)
        site.rows("Sponsor").each do |row|
          level_id = row.attributes["level_id"]
          if level_id && !level_ids.include?(level_id)
            raise Invalid, "#{site.tenant_name} Sponsor##{row.id} points at SponsorLevel##{level_id}, which is not in the dump"
          end

          @sponsors << SponsorRow.new([ "Sponsor", row.id ], level_id && [ "SponsorLevel", level_id ], carried(row), row.upload)
        end
      end

      # Names compare as the whole JSONB value, locales and all; a partner is skipped
      # when a sponsor — or a partner already taken in — holds its name.
      def plan_partners
        taken = @sponsors.map { |sponsor| sponsor.attributes["name"] }
        site.rows("Partner").each do |row|
          name = row.attributes["name"]
          next @skipped_partners << row if taken.include?(name)

          taken << name
          @sponsors << SponsorRow.new([ "Partner", row.id ], level_for_partner(row), carried(row), row.upload)
        end
      end

      def level_for_partner(row)
        type_id = row.attributes["type_id"]
        return unless type_id

        @level_by_type.fetch(type_id) do
          raise Invalid, "#{site.tenant_name} Partner##{row.id} points at PartnerType##{type_id}, which is not in the dump"
        end
      end

      def carried(row)
        row.attributes.except(*DROPPED)
      end
    end
  end
end
