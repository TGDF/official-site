# frozen_string_literal: true

class AddSiteIdToSpeakers < ActiveRecord::Migration[7.0]
  def change
    add_column :speakers, :site_id, :bigint

    add_index :speakers, %i[site_id slug], unique: true
  end
end
