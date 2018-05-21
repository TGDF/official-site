# frozen_string_literal: true

class SpeakersController < ApplicationController
  def index
    @speakers = Speaker.all
  end
end
