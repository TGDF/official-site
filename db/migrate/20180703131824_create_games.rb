# frozen_string_literal: true

class CreateGames < ActiveRecord::Migration[5.1]
  def change
    create_table :games do |t|
      t.jsonb :name, null: false
      t.jsonb :description, null: false
      t.jsonb :team, null: false
      t.string :video
      t.string :thumbnail

      t.timestamps
    end
  end
end
