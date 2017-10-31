# frozen_string_literal: true

module Admin
  class SponsorsController < Admin::BaseController
    before_action :find_sponsor, except: %i[index new create]

    def index
      @sponsors = Sponsor.all
    end

    def new
      @sponsor = Sponsor.new
    end

    def create
      @sponsor = Sponsor.new(sponsor_params)
      return redirect_to admin_sponsors_path if @sponsor.save
      render :new
    end

    def edit; end

    def update
      return redirect_to admin_sponsors_path if @sponsor.update(sponsor_params)
      render :edit
    end

    def destroy
      @sponsor.destroy
      redirect_to admin_sponsors_path
    end

    private

    def find_sponsor
      @sponsor = Sponsor.find(params[:id])
    end

    def sponsor_params
      params.require(:sponsor).permit(
        :name, :logo, :remove_logo, :level_id, :url, :locale
      )
    end
  end
end
