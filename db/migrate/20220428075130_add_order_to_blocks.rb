# frozen_string_literal: true

class AddOrderToBlocks < ActiveRecord::Migration[6.1]
  def change
    add_column :blocks, :order, :integer, default: 0, null: false
  end
end
