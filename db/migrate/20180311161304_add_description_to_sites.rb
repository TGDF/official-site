# frozen_string_literal: true

class AddDescriptionToSites < ActiveRecord::Migration[5.1]
  def change
    add_column(:sites, :description, :jsonb, default: {})
  end
end
