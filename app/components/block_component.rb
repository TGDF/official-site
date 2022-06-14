# frozen_string_literal: true

class BlockComponent < ViewComponent::Base
  with_collection_parameter :block

  delegate_missing_to :@block

  def initialize(block:)
    super
    @block = block
  end
end
