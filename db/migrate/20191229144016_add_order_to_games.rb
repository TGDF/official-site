# frozen_string_literal: true

class AddOrderToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :order, :integer, default: 0
  end
end
