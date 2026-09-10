# frozen_string_literal: true

module TenantConsolidation
  # The sponsor group. SponsorLevel and Sponsor move as they are; the retired
  # PartnerType and Partner rows fold into them on the way — each PartnerType becomes
  # a SponsorLevel of the same name, each Partner a Sponsor under it.
  module SponsorGroup
    NAME = "sponsor"
    MODELS = %w[SponsorLevel Sponsor PartnerType Partner].freeze
    UPLOADS = { "Sponsor" => :logo, "Partner" => :logo }.freeze

    # 2023tgdf paired its PartnerType labels the other way round from every other
    # year. Keyed by the English label, the zh-TW label every other year gives it.
    LABEL_FIXES = {
      "2023tgdf" => { "Supporting Partners" => "合作單位", "Co-organizers" => "協辦單位" }
    }.freeze

    module_function

    def collect
      Dump.collect(group: NAME, models: MODELS, uploads: UPLOADS)
    end

    # The name a PartnerType from `tenant_name` carries once it is a SponsorLevel.
    def level_name_for(tenant_name, name)
      fixed = LABEL_FIXES.dig(tenant_name, name&.dig("en"))
      fixed ? name.merge("zh-TW" => fixed) : name
    end
  end
end
