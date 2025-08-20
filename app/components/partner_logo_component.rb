# frozen_string_literal: true

class PartnerLogoComponent < ViewComponent::Base
  with_collection_parameter :partner

  delegate_missing_to :@partner

  def initialize(partner:)
    super()
    @partner = partner
  end
end
