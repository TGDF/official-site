# frozen_string_literal: true

module Admin
  class GamesController < Admin::BaseController
    before_action :find_game, except: %i[index new create]

    def index
      @games = resource.all
    end

    def new
      @game = resource.new
    end

    def edit; end

    def create
      Mobility.with_locale(I18n.default_locale) do
        return redirect_to(index_path) if resource.create(game_params)

        render :new, status: :unprocessable_entity
      end
    end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to(index_path) if @game.update(game_params)

        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @game.destroy
      redirect_to index_path
    end

    private

    def resource
      raise NotImplementedError
    end

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

    def index_path
      polymorphic_url([:admin, resource])
    end
  end
end
