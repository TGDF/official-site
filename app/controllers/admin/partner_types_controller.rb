# frozen_string_literal: true

module Admin
  class PartnerTypesController < Admin::BaseController
    def index
      @types = PartnerType.all
    end

    def new
      @type = PartnerType.new
    end

    def create
      @type = PartnerType.create(partner_type_params)
      return redirect_to admin_partner_types_path if @type.save
      render :new
    end

    private

    def partner_type_params
      params.require(:partner_type).permit(:name)
    end
  end
end
