# frozen_string_literal: true

class SpeakersController < ApplicationController
  def index
    @speakers = Speaker.all
  end

  def show
    @speaker = Speaker.includes(:agendas).find(params[:id])
  end
end
