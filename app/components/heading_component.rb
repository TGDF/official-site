# frozen_string_literal: true

class HeadingComponent < ViewComponent::Base
  def initialize(text:)
    super()
    @text = text
  end
end
