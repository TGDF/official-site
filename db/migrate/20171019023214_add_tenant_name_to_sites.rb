# frozen_string_literal: true

class AddTenantNameToSites < ActiveRecord::Migration[5.1]
  def change
    add_column(:sites, :tenant_name, :string)
    add_index(:sites, :tenant_name)
  end
end
