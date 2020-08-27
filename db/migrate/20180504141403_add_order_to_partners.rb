# frozen_string_literal: true

class AddOrderToPartners < ActiveRecord::Migration[5.1]
  def change
    add_column(:partners, :order, :integer, default: 0)
    add_column(:partner_types, :order, :integer, default: 0)
  end
end
