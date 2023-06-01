# frozen_string_literal: true

module Admin
  class PlansController < Admin::BaseController
    def index
      @plans = Plan.all
    end
  end
end
