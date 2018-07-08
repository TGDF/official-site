# frozen_string_literal: true

class IndieSpacesController < ApplicationController
  def index
    @sliders = Slider.localized.indie_space
    @games = Game.all
  end
end
