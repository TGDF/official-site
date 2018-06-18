# frozen_string_literal: true

class AgendasController < ApplicationController
  def show
    @days = AgendaDay.all.includes(:times)
  end
end
