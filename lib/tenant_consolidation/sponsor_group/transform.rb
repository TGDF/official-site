# frozen_string_literal: true

module TenantConsolidation
  module SponsorGroup
    # The sponsor group's plan for one dumped site:
    #
    #   SponsorLevel ───────────────────────────────▶ level
    #   PartnerType ── same-site level of that name? ─ yes ─▶ (reuses it)
    #                                               └ no ──▶ level, 2023tgdf label fixed
    #   Sponsor ───────────────────────────────────▶ sponsor under its level
    #   Partner ── name taken in the site? ── yes ─▶ skipped, left for review
    #                                     └── no ──▶ sponsor under its type's level
    #
    # A sponsor's `level_id` ref is the source of its level, which for a merged
    # partner may be a PartnerType.
    class Transform
      LabelFix = Data.define(:partner_type_id, :from, :to)

      DROPPED = (Plan::DROPPED + %w[level_id type_id]).freeze

      attr_reader :site, :skipped_partners, :label_fixes

      def initialize(site)
        @site = site
        @levels = []
        @sponsors = []
        @skipped_partners = []
        @label_fixes = []
        @level_by_type = {}
        plan_levels
        plan_partner_types
        plan_sponsors
        plan_partners
      end

      def plan
        Plan.new(site, rows: @levels + @sponsors, skipped: { "Partner" => skipped_partners })
      end

      private

      def plan_levels
        site.rows("SponsorLevel").each do |row|
          @levels << level_row([ "SponsorLevel", row.id ], carried(row))
        end
      end

      def plan_partner_types
        site.rows("PartnerType").each do |row|
          name = row.attributes["name"]
          fixed = SponsorGroup.level_name_for(site.tenant_name, name)
          @label_fixes << LabelFix.new(row.id, name, fixed) unless fixed == name

          @level_by_type[row.id] = existing_level_named(fixed) || begin
            @levels << level_row([ "PartnerType", row.id ], carried(row).merge("name" => fixed))
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
            raise Plan::Invalid, "#{site.tenant_name} Sponsor##{row.id} points at SponsorLevel##{level_id}, which is not in the dump"
          end

          @sponsors << sponsor_row([ "Sponsor", row.id ], level_id && [ "SponsorLevel", level_id ], row)
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
          @sponsors << sponsor_row([ "Partner", row.id ], level_for_partner(row), row)
        end
      end

      def level_for_partner(row)
        type_id = row.attributes["type_id"]
        return unless type_id

        @level_by_type.fetch(type_id) do
          raise Plan::Invalid, "#{site.tenant_name} Partner##{row.id} points at PartnerType##{type_id}, which is not in the dump"
        end
      end

      def level_row(source, attributes)
        Plan::Row.new(source, "SponsorLevel", attributes, {}, nil)
      end

      def sponsor_row(source, level, row)
        Plan::Row.new(source, "Sponsor", carried(row), { "level_id" => level }, row.upload)
      end

      def carried(row)
        row.attributes.except(*DROPPED)
      end
    end
  end
end
