# frozen_string_literal: true

class AddSiteIdToRooms < ActiveRecord::Migration[7.0]
  def change
    add_column :rooms, :site_id, :bigint
  end
end
