# frozen_string_literal: true

class CreateMenuItems < ActiveRecord::Migration[7.0]
  def change
    create_table :menu_items do |t|
      t.string :menu_id
      t.jsonb :name
      t.jsonb :link
      t.integer :position, default: 0, null: false
      t.boolean :visible, default: true, null: false

      t.timestamps
    end
  end
end
