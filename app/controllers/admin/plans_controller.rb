# frozen_string_literal: true

module Admin
  class PlansController < Admin::BaseController
    before_action :find_plan, except: %i[index new create]

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

        render :new, status: :unprocessable_entity
      end
    end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to(admin_plans_path) if @plan.update(plan_params)

        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @plan.destroy
      redirect_to admin_plans_path
    end

    private

    def plan_params
      params
        .require(:plan)
        .permit(:name, :content, :button_label, :button_target)
    end

    def find_plan
      @plan = Plan.find(params[:id])
    end
  end
end
