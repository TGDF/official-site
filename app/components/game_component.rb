# frozen_string_literal: true

class GameComponent < ViewComponent::Base
  def initialize(game:)
    super
    @game = game
  end
end
