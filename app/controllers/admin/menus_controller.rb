# frozen_string_literal: true

module Admin
  class MenusController < Admin::BaseController
    def index
      @menus = MenuItem.all
    end
  end
end
