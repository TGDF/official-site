# frozen_string_literal: true

class AddIndieSpaceDescriptionToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :indie_space_description, :jsonb
  end
end
