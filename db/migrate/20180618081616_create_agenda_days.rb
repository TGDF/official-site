# frozen_string_literal: true

class CreateAgendaDays < ActiveRecord::Migration[5.1]
  def change
    create_table :agenda_days do |t|
      t.string(:label)
      t.date(:date, null: false, default: -> { 'NOW()' })

      t.timestamps
    end
  end
end
