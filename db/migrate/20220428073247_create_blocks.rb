# frozen_string_literal: true

class CreateBlocks < ActiveRecord::Migration[6.1]
  def change
    create_table :blocks do |t|
      t.text :content
      t.string :language, default: :'zh-TW', null: false
      t.string :page, null: false
      t.string :component_type, default: :text, null: false

      t.timestamps
    end
  end
end
