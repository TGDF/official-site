# frozen_string_literal: true

class PartnerGroupComponent < ViewComponent::Base
  with_collection_parameter :group

  delegate_missing_to :@group

  def initialize(group:)
    super
    @group = group
  end
end
