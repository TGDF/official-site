# frozen_string_literal: true

class CreateSponsorLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :sponsor_levels do |t|
      t.jsonb :name, default: {}

      t.timestamps
    end
  end
end
