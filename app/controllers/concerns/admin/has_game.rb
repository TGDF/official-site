# frozen_string_literal: true

module Admin
  module HasGame
    extend ActiveSupport::Concern

    included do
      def game_params
        params
          .require(resource_name)
          .permit(:name, :description, :team, :video, :order,
                  :thumbnail, :website, :remove_thumbnail)
      end
    end
  end
end
