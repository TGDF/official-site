# frozen_string_literal: true

class SliderItemComponent < ViewComponent::Base
  with_collection_parameter :slider

  def initialize(slider:, slider_iteration:)
    super
    @slider = slider
    @iteration = slider_iteration
  end

  def classes
    item = %w[swiper-slide]
    item << %w[active] if @iteration.first?
    item.join(" ")
  end
end
