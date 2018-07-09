# frozen_string_literal: true

module Admin
  class GamesController < Admin::BaseController
    before_action :find_game, only: %i[edit update destroy]

    def index
      @games = Game.all
    end

    def new
      @game = Game.new
    end

    def create
      Mobility.with_locale(I18n.default_locale) do
        return redirect_to admin_games_path if Game.create(game_params)
        render :new
      end
    end

    def edit; end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to admin_games_path if @game.update(game_params)
        render :edit
      end
    end

    def destroy
      @game.destroy
      redirect_to admin_games_path
    end

    private

    def find_game
      @game = Game.find(params[:id])
    end

    def game_params
      params
        .require(:game)
        .permit(:name, :description, :team, :video,
                :thumbnail, :website, :remove_thumbnail)
    end
  end
end
