class AddOrderToSponsors < ActiveRecord::Migration[5.1]
  def change
    add_column :sponsors, :order, :integer, default: 0
    add_column :sponsor_levels, :order, :integer, default: 0
  end
end
