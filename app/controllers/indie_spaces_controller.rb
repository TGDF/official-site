# frozen_string_literal: true

class IndieSpacesController < ApplicationController
  def index
    @sliders = Slider.localized.indie_spaces
    @games = Game.all
  end
end
