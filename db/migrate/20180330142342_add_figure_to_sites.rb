class AddFigureToSites < ActiveRecord::Migration[5.1]
  def change
    add_column :sites, :figure, :string
  end
end
