# frozen_string_literal: true

module Admin
  class MenuItemsController < Admin::BaseController
    before_action :find_menu_item, except: %i[index new create]

    def index
      @menu_items = MenuItem.all
    end

    def new
      @menu_item = MenuItem.new
    end

    def create
      Mobility.with_locale(I18n.default_locale) do
        @menu_item = MenuItem.new(menu_item_params)
        return redirect_to(admin_menu_items_path) if @menu_item.save

        render :new, status: :unprocessable_entity
      end
    end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to(admin_menu_items_path) if @menu_item.update(menu_item_params)

        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @menu_item.destroy
      redirect_to admin_menu_items_path
    end

    private

    def menu_item_params
      params
        .require(:menu_item)
        .permit(:name, :link, :visible, :menu_id)
    end

    def find_menu_item
      @menu_item = MenuItem.find(params[:id])
    end
  end
end
