# frozen_string_literal: true

class SpeakersController < ApplicationController
  def index
    @speakers = Speaker.with_attached_avatar_attachment
  end

  def show
    @speaker = Speaker.includes(agendas: { time: :day }).friendly.find(params[:id])
  end
end
