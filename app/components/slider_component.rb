# frozen_string_literal: true

class SliderComponent < ViewComponent::Base
  def initialize(id:, sliders:)
    super()
    @id = id
    @sliders = sliders
  end

  def options
    {
      lazy: true,
      loop: @sliders.size > 1,
      autoplay: {
        delay: 5000,
        disableOnInteraction: false,
        pauseOnMouseEnter: true
      }
    }
  end
end
