# frozen_string_literal: true

class PartnerItemComponent < ViewComponent::Base
  with_collection_parameter :item

  delegate_missing_to :@item

  def initialize(item:)
    super
    @item = item
  end
end
