class AddPageToSliders < ActiveRecord::Migration[5.1]
  def change
    add_column :sliders, :page, :integer, null: false, default: 0
  end
end
