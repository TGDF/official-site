# frozen_string_literal: true

class AddOrderToAgendas < ActiveRecord::Migration[5.1]
  def change
    add_column(:agendas, :order, :integer, default: 0, null: false)
  end
end
