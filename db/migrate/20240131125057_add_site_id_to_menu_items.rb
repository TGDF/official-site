# frozen_string_literal: true

class AddSiteIdToMenuItems < ActiveRecord::Migration[7.0]
  def change
    add_column :menu_items, :site_id, :bigint, null: true
    add_index :menu_items, :site_id
  end
end
