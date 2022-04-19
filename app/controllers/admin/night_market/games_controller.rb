# frozen_string_literal: true

module Admin
  module NightMarket
    class GamesController < Admin::BaseController
      include Admin::HasGame

      def index
        @games = ::NightMarket::Game.all
      end

      def new
        @game = ::NightMarket::Game.new
      end

      def create
        Mobility.with_locale(I18n.default_locale) do
          return redirect_to(admin_night_market_games_path) if ::NightMarket::Game.create(game_params)

          render :new
        end
      end

      def update
        Mobility.with_locale(admin_current_resource_locale) do
          return redirect_to(admin_night_market_games_path) if @game.update(game_params)

          render :edit
        end
      end

      private

      def resource
        ::NightMarket::Game
      end
    end
  end
end
