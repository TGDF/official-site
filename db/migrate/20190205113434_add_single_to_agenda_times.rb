# frozen_string_literal: true

class AddSingleToAgendaTimes < ActiveRecord::Migration[5.1]
  def change
    add_column(:agenda_times, :single, :bool)
  end
end
