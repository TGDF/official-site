# frozen_string_literal: true

module Admin
  class PartnerTypesController < Admin::BaseController
    def index
      @types = PartnerType.all
    end
  end
end
