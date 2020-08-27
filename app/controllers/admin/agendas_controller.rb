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
      Mobility.with_locale(I18n.default_locale) do
        @agenda = Agenda.new(agenda_params)
        return redirect_to(admin_agendas_path) if @agenda.save

        render :new
      end
    end

    def edit; end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to(admin_agendas_path) if @agenda.update(agenda_params)

        render :edit
      end
    end

    def destroy
      @agenda.destroy
      redirect_to(admin_agendas_path)
    end

    private

    def find_agenda
      @agenda = Agenda.find(params[:id])
    end

    def agenda_params
      params
        .require(:agenda)
        .permit(:subject, :description, :room_id, :time_id,
                :language, :translated_language, :translated_type,
                :begin_at, :end_at,
                :order, speaker_ids: [], tag_ids: [])
    end
  end
end
