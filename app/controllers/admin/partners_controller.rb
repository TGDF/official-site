# frozen_string_literal: true

module Admin
  class PartnersController < Admin::BaseController
    before_action :find_partner, except: %i[index new create]

    def index
      @partners = Partner.includes(:type).all
    end

    def new
      @partner = Partner.new
    end

    def create
      Mobility.with_locale(I18n.default_locale) do
        @partner = Partner.new(partner_params)
        return redirect_to(admin_partners_path) if @partner.save

        render :new
      end
    end

    def edit; end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to(admin_partners_path) if @partner.update(partner_params)

        render :edit
      end
    end

    def destroy
      @partner.destroy
      redirect_to(admin_partners_path)
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
