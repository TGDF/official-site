# frozen_string_literal: true

class IndieSpacesController < ApplicationController
  before_action :check_is_opened

  def index
    @sliders = Slider.localized.indie_spaces.with_attached_image_attachment
    @games = IndieSpace::Game.with_attached_thumbnail_attachment
  end

  private

  def check_is_opened
    return unless current_site.indie_space_disabled?

    redirect_to(root_path)
  end
end
