# frozen_string_literal: true

module Admin
  class AgendaDaysController < Admin::BaseController
    before_action :find_agenda_day, except: %i[index new create]

    def index
      @agenda_days = AgendaDay.all
    end

    def new
      @agenda_day = AgendaDay.new
    end

    def edit; end

    def create
      @agenda_day = AgendaDay.new(agenda_day_params)
      return redirect_to(admin_agenda_days_path) if @agenda_day.save

      render(:new)
    end

    def update
      return redirect_to(admin_agenda_days_path) if @agenda_day.update(agenda_day_params)

      render(:edit)
    end

    def destroy
      @agenda_day.destroy
      redirect_to(admin_agenda_days_path)
    end

    private

    def find_agenda_day
      @agenda_day = AgendaDay.find(params[:id])
    end

    def agenda_day_params
      params.require(:agenda_day).permit(:label, :date)
    end
  end
end
