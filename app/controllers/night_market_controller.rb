# frozen_string_literal: true

class NightMarketController < ApplicationController
  def index
    @blocks = Block.ordered.localized.night_market
    @sliders = Slider.localized.night_market
    @games = NightMarket::Game.all
  end
end
