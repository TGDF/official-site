# frozen_string_literal: true

class IndieSpacesController < ApplicationController
  before_action :check_is_opened

  def index
    @sliders = Slider.localized.indie_spaces
    @games = IndieSpace::Game.all
  end

  private

  def check_is_opened
    return unless current_site.indie_space_disabled?

    redirect_to(root_path)
  end
end
