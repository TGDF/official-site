class CreateNews < ActiveRecord::Migration[5.1]
  def change
    create_table :news do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.references :author, polymorphic: true, index: true
      t.string :slug, null: false
      t.integer :status, default: 0

      t.timestamps
    end

    add_index :news, :slug, unique: true
    add_index :news, :status
  end
end
