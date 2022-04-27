# frozen_string_literal: true

class SliderComponent < ViewComponent::Base
  def initialize(id:, sliders:)
    super
    @id = id
    @sliders = sliders
  end
end
