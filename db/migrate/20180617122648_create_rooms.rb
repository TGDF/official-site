# frozen_string_literal: true

class CreateRooms < ActiveRecord::Migration[5.1]
  def change
    create_table :rooms do |t|
      t.string(:name)
      t.integer(:order, null: false, default: 0)

      t.timestamps
    end
  end
end
