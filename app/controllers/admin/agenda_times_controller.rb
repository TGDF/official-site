# frozen_string_literal: true

module Admin
  class AgendaTimesController < Admin::BaseController
    before_action :find_agenda_time, except: %i[index new create]

    def index
      @agenda_times = AgendaTime.all
    end

    def new
      @agenda_time = AgendaTime.new
    end

    def create
      @agenda_time = AgendaTime.new(agenda_time_params)
      return redirect_to admin_agenda_times_path if @agenda_time.save

      render :new
    end

    def edit; end

    def update
      if @agenda_time.update(agenda_time_params)
        return redirect_to admin_agenda_times_path
      end

      render :edit
    end

    def destroy
      @agenda_time.destroy
      redirect_to admin_agenda_times_path
    end

    private

    def find_agenda_time
      @agenda_time = AgendaTime.find(params[:id])
    end

    def agenda_time_params
      params.require(:agenda_time).permit(:label, :order, :day_id)
    end
  end
end
