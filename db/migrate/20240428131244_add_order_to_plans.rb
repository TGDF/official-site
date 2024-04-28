# frozen_string_literal: true

class AddOrderToPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :plans, :order, :integer, null: false, default: 0
  end
end
