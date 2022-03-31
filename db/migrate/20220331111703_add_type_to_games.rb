# frozen_string_literal: true

class AddTypeToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :type, :string
  end
end
