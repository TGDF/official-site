# frozen_string_literal: true

class SliderItemComponent < ViewComponent::Base
  with_collection_parameter :slider

  def initialize(slider:)
    super
    @slider = slider
  end
end
