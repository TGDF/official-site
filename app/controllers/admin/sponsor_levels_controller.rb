# frozen_string_literal: true

module Admin
  class SponsorLevelsController < Admin::BaseController
    before_action :find_sponsor_level, except: %i[index new create]

    def index
      @levels = SponsorLevel.all
    end

    def new
      @level = SponsorLevel.new
    end

    def edit; end

    def create
      Mobility.with_locale(I18n.default_locale) do
        @level = SponsorLevel.new(sponsor_level_params)
        return redirect_to(admin_sponsor_levels_path) if @level.save

        render :new
      end
    end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to(admin_sponsor_levels_path) if @level.update(sponsor_level_params)

        render :edit
      end
    end

    def destroy
      @level.destroy
      redirect_to(admin_sponsor_levels_path)
    end

    private

    def find_sponsor_level
      @level = SponsorLevel.find(params[:id])
    end

    def sponsor_level_params
      params.require(:sponsor_level).permit(:name, :order)
    end
  end
end
