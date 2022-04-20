# frozen_string_literal: true

class NightMarketController < ApplicationController
  def index
    @games = NightMarket::Game.all
  end
end
