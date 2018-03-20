# frozen_string_literal: true

class CreateSponsors < ActiveRecord::Migration[5.1]
  def change
    create_table :sponsors do |t|
      t.jsonb :name, default: {}
      t.string :logo
      t.string :url
      t.references(
        :level,
        foreign_key: { to_table: :sponsor_levels },
        index: true
      )

      t.timestamps
    end
  end
end
