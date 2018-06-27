class AddDescriptionToPartners < ActiveRecord::Migration[5.1]
  def change
    add_column :partners, :description, :jsonb
  end
end
