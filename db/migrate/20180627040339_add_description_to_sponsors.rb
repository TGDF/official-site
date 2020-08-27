# frozen_string_literal: true

class AddDescriptionToSponsors < ActiveRecord::Migration[5.1]
  def change
    add_column(:sponsors, :description, :jsonb)
  end
end
