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

      def create
        Mobility.with_locale(I18n.default_locale) do
          return redirect_to(admin_night_market_games_path) if ::NightMarket::Game.create(game_params)

          render :new
        end
      end

      private

      def game_params
        params
          .require(:night_market_game)
          .permit(:name, :description, :team, :video, :order,
                  :thumbnail, :website, :remove_thumbnail)
      end
    end
  end
end
