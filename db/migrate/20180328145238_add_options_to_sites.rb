class AddOptionsToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :options, :jsonb
  end
end
