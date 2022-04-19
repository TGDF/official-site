# frozen_string_literal: true

module Admin
  module HasGame
    extend ActiveSupport::Concern

    included do
      before_action :find_game, except: %i[index new create] # rubocop:disable Rails/LexicallyScopedActionFilter

      private

      def game_params
        params
          .require(resource_name)
          .permit(:name, :description, :team, :video, :order,
                  :thumbnail, :website, :remove_thumbnail)
      end

      def find_game
        @game = resource.find(params[:id])
      end

      def resource_name
        resource.model_name.singular
      end
    end
  end
end
