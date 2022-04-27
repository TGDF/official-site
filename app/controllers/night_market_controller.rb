# frozen_string_literal: true

class NightMarketController < ApplicationController
  def index
    @sliders = Slider.localized.night_market
    @games = NightMarket::Game.all
  end
end
