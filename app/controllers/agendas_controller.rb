# frozen_string_literal: true

class AgendasController < ApplicationController
  def show
    @days = AgendaDay.all
    q = params[:day].try(:to_i)
    @query_day = AgendaDay.exists?(q) ? q : @days.first.id
    @day = AgendaDay.includes(times: { agendas: %i[room speakers] })
                    .find(@query_day)
  end
end
