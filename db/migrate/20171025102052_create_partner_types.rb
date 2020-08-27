# frozen_string_literal: true

class CreatePartnerTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :partner_types do |t|
      t.jsonb(:name, default: {})

      t.timestamps
    end
  end
end
