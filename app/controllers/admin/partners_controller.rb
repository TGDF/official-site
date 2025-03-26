# frozen_string_literal: true

module Admin
  class PartnersController < Admin::BaseController
    before_action :find_partner, except: %i[index new create]

    def index
      @partners = Partner.includes(:type).all
    end

    def new
      redirect_to admin_partner_types_path, alert: t(".deprecated")
    end

    def edit
      redirect_to admin_partner_types_path, alert: t(".deprecated")
    end

    def create
      redirect_to admin_partner_types_path, alert: t(".deprecated")
    end

    def update
      redirect_to admin_partner_types_path, alert: t(".deprecated")
    end

    def destroy
      @partner.destroy
      redirect_to admin_partners_path
    end

    private

    def find_partner
      @partner = Partner.find(params[:id])
    end

    def partner_params
      params.require(:partner).permit(
        :name, :logo, :remove_logo, :type_id, :url, :order, :description
      )
    end
  end
end
