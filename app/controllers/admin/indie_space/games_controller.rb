# frozen_string_literal: true

module Admin
  module IndieSpace
    class GamesController < Admin::GamesController
      def resource
        ::IndieSpace::Game
      end
    end
  end
end
