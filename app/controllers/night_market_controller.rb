# frozen_string_literal: true

class NightMarketController < ApplicationController
  def index
    @blocks = Block.ordered.localized.night_market
    @sliders = Slider.localized.night_market.with_attached_image_attachment
    @games = NightMarket::Game.with_attached_thumbnail_attachment
  end
end
