# frozen_string_literal: true

class AgendasController < ApplicationController
  def show
    @rooms = Room.all
    @days = AgendaDay.all.includes(times: { agendas: %i[room speakers] })
  end
end
