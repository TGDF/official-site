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

    def edit; end

    def create
      Mobility.with_locale(I18n.default_locale) do
        @type = PartnerType.create(partner_type_params)
        return redirect_to(admin_partner_types_path) if @type.save

        render :new
      end
    end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to(admin_partner_types_path) if @type.update(partner_type_params)

        render :edit
      end
    end

    def destroy
      @type.destroy
      redirect_to(admin_partner_types_path)
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
