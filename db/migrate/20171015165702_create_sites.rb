# frozen_string_literal: true

class CreateSites < ActiveRecord::Migration[5.1]
  def change
    create_table :sites do |t|
      t.string :domain, null: false
      t.jsonb :name, default: {}

      t.timestamps
    end

    add_index :sites, :domain
  end
end
