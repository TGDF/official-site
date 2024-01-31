# frozen_string_literal: true

class AddSiteIdToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :site_id, :bigint, null: true
    add_index :games, :site_id
  end
end
