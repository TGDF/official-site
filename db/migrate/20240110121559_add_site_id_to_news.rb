# frozen_string_literal: true

class AddSiteIdToNews < ActiveRecord::Migration[7.0]
  def change
    change_table :news do |t|
      t.bigint :site_id, null: true
      t.index %i[site_id slug], unique: true
    end
  end
end
