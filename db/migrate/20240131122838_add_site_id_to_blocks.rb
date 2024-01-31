# frozen_string_literal: true

class AddSiteIdToBlocks < ActiveRecord::Migration[7.0]
  def change
    add_column :blocks, :site_id, :bigint, null: true
    add_index :blocks, :site_id
  end
end
