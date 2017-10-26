# frozen_string_literal: true

module Admin
  class PartnersController < Admin::BaseController
    def index
      @partners = Partner.includes(:type).all
    end

    def new
      @partner = Partner.new
    end

    def create
      @partner = Partner.new(partner_params)
      return redirect_to admin_partners_path if @partner.save
      render :new
    end

    private

    def partner_params
      params.require(:partner).permit(:name, :logo, :type_id, :locale)
    end
  end
end
