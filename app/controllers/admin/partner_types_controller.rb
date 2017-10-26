# frozen_string_literal: true

module Admin
  class PartnerTypesController < Admin::BaseController
    before_action :find_type, except: %i[index new create]

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

    def edit; end

    def update
      if @type.update(partner_type_params)
        return redirect_to admin_partner_types_path
      end
      render :edit
    end

    private

    def find_type
      @type = PartnerType.find(params[:id])
    end

    def partner_type_params
      params.require(:partner_type).permit(:name, :locale)
    end
  end
end
