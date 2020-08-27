# frozen_string_literal: true

class CreatePartners < ActiveRecord::Migration[5.1]
  def change
    create_table :partners do |t|
      t.jsonb(:name, default: {})
      t.string(:logo)
      t.references(:type, foreign_key: { to_table: :partner_types }, index: true)

      t.timestamps
    end
  end
end
