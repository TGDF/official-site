# frozen_string_literal: true

class AddTimeAndRoomToAgendas < ActiveRecord::Migration[5.1]
  def change
    add_reference(:agendas, :time, foreign_key: { to_table: :agenda_times })
    add_reference(:agendas, :room, foreign_key: true)
  end
end
