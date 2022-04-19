# frozen_string_literal: true

module Admin
  module NightMarket
    class GamesController < Admin::GamesController
      def resource
        ::NightMarket::Game
      end
    end
  end
end
