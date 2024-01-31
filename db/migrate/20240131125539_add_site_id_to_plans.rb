# frozen_string_literal: true

class AddSiteIdToPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :plans, :site_id, :bigint, null: true
    add_index :plans, :site_id
  end
end
