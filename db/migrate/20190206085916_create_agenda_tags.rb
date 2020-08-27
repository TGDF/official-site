# frozen_string_literal: true

class CreateAgendaTags < ActiveRecord::Migration[5.1]
  def change
    create_table :agenda_tags do |t|
      t.jsonb(:name)

      t.timestamps
    end
  end
end
