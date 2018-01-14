# frozen_string_literal: true

module Admin
  class AgendasController < Admin::BaseController
    before_action :find_agenda, except: %i[index new create]

    def index
      @agendas = Agenda.all
    end

    def new
      @agenda = Agenda.new
    end

    def create
      @agenda = Agenda.new(agenda_params)
      return redirect_to admin_agendas_path if @agenda.save
      render :new
    end

    def edit; end

    def update
      return redirect_to admin_agendas_path if @agenda.update(agenda_params)
      render :edit
    end

    def destroy
      @agenda.destroy
      redirect_to admin_agendas_path
    end

    private

    def find_agenda
      @agenda = Agenda.find(params[:id])
    end

    def agenda_params
      params
        .require(:agenda)
        .permit(:subject, :description, :locale)
    end
  end
end
