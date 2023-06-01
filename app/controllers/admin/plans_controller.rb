# frozen_string_literal: true

module Admin
  class PlansController < Admin::BaseController
    def index
      @plans = Plan.all
    end

    def new
      @plan = Plan.new
    end

    def create
      Mobility.with_locale(I18n.default_locale) do
        @plan = Plan.new(plan_params)
        return redirect_to(admin_plans_path) if @plan.save

        render :new
      end
    end

    private

    def plan_params
      params
        .require(:plan)
        .permit(:name, :content, :button_label, :button_target)
    end
  end
end
