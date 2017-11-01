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
      @speaker = Speaker.new(speaker_params)
      return redirect_to admin_speakers_path if @speaker.save
      render :new
    end

    def edit; end

    def update
      return redirect_to admin_speakers_path if @speaker.update(speaker_params)
      render :edit
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
        .permit(:name, :description, :avatar, :remove_avatar, :locale)
    end
  end
end
