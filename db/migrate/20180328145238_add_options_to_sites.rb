# frozen_string_literal: true

class AddOptionsToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :options, :jsonb
  end
end
