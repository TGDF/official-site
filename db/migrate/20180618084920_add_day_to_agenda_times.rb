# frozen_string_literal: true

class AddDayToAgendaTimes < ActiveRecord::Migration[5.1]
  def change
    add_reference(:agenda_times, :day, foreign_key: { to_table: :agenda_days })
  end
end
