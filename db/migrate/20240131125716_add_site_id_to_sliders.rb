# frozen_string_literal: true

class AddSiteIdToSliders < ActiveRecord::Migration[7.0]
  def change
    add_column :sliders, :site_id, :bigint, null: true
    add_index :sliders, :site_id
  end
end
