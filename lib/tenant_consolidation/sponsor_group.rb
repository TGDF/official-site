# frozen_string_literal: true

module TenantConsolidation
  # The sponsor group. SponsorLevel and Sponsor move as they are; the retired
  # PartnerType and Partner rows fold into them on the way — each PartnerType becomes
  # a SponsorLevel of the same name, each Partner a Sponsor under it.
  module SponsorGroup
    NAME = "sponsor"
    MODELS = %w[SponsorLevel Sponsor PartnerType Partner].freeze
    UPLOADS = { "Sponsor" => :logo, "Partner" => :logo }.freeze
    TARGETS = %w[SponsorLevel Sponsor].freeze
    SHARED = [].freeze

    # 2023tgdf paired its PartnerType labels the other way round from every other
    # year. Keyed by the English label, the zh-TW label every other year gives it.
    LABEL_FIXES = {
      "2023tgdf" => { "Supporting Partners" => "合作單位", "Co-organizers" => "協辦單位" }
    }.freeze

    module_function

    def plan(site)
      Transform.new(site).plan
    end

    # The name a PartnerType from `tenant_name` carries once it is a SponsorLevel.
    def level_name_for(tenant_name, name)
      fixed = LABEL_FIXES.dig(tenant_name, name&.dig("en"))
      fixed ? name.merge("zh-TW" => fixed) : name
    end

    def census_sections(dump)
      transforms = dump.sites.map { |site| Transform.new(site) }
      [
        [ "Partners named like a Sponsor of the same site (skipped on import)",
          transforms.flat_map do |transform|
            transform.skipped_partners.map do |row|
              "#{transform.site.tenant_name} Partner##{row.id} #{row.attributes['name']}"
            end
          end ],
        [ "PartnerType labels corrected on import",
          transforms.flat_map do |transform|
            transform.label_fixes.map do |fix|
              "#{transform.site.tenant_name} PartnerType##{fix.partner_type_id} #{fix.from} → #{fix.to}"
            end
          end ]
      ]
    end
  end
end
