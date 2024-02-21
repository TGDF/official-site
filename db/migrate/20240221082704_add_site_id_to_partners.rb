# frozen_string_literal: true

class AddSiteIdToPartners < ActiveRecord::Migration[7.0]
  def change
    add_column :partners, :site_id, :bigint
    add_column :partner_types, :site_id, :bigint

    add_index :partners, %i[site_id type_id]
  end
end
