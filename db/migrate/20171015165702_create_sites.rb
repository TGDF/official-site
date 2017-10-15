class CreateSites < ActiveRecord::Migration[5.1]
  def change
    create_table :sites do |t|
      t.string :domain, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :sites, :domain
  end
end
