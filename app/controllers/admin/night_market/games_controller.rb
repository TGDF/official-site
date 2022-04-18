# frozen_string_literal: true

module Admin
  module NightMarket
    class GamesController < Admin::BaseController
      def index
        @games = ::NightMarket::Game.all
      end

      def new
        @game = ::NightMarket::Game.new
      end
    end
  end
end
