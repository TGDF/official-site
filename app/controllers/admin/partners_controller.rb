# frozen_string_literal: true

module Admin
  class PartnersController < Admin::BaseController
    def index
      @partners = Partner.includes(:type).all
    end
  end
end
