# frozen_string_literal: true

class AddSiteIdToSponsors < ActiveRecord::Migration[7.0]
  def change
    add_column :sponsors, :site_id, :bigint
    add_column :sponsor_levels, :site_id, :bigint

    add_index :sponsors, %i[site_id level_id]
  end
end
