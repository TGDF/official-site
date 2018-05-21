# frozen_string_literal: true

module Admin
  class SpeakersController < Admin::BaseController
    before_action :find_speaker, except: %i[index new create]

    def index
      @speakers = Speaker.all
    end

    def new
      @speaker = Speaker.new
    end

    def create
      Mobility.with_locale(I18n.default_locale) do
        @speaker = Speaker.new(speaker_params)
        return redirect_to admin_speakers_path if @speaker.save
        render :new
      end
    end

    def edit; end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        if @speaker.update(speaker_params)
          return redirect_to admin_speakers_path
        end
        render :edit
      end
    end

    def destroy
      @speaker.destroy
      redirect_to admin_speakers_path
    end

    private

    def find_speaker
      @speaker = Speaker.find(params[:id])
    end

    def speaker_params
      params
        .require(:speaker)
        .permit(:name, :title, :description, :avatar, :remove_avatar)
    end
  end
end
