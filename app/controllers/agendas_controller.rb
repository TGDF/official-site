# frozen_string_literal: true

class AgendasController < ApplicationController
  def show
    @rooms = Room.all
    @days = AgendaDay.includes(times: { agendas: %i[room speakers tags] })
  end
end
