# frozen_string_literal: true

module Admin
  class PartnerTypesController < Admin::BaseController
    before_action :find_type, except: %i[index new create]

    def index
      @types = PartnerType.all
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
      @type.destroy
      redirect_to admin_partner_types_path
    end

    private

    def find_type
      @type = PartnerType.find(params[:id])
    end

    def partner_type_params
      params.require(:partner_type).permit(:name, :order)
    end
  end
end
