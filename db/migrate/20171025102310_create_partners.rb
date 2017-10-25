class CreatePartners < ActiveRecord::Migration[5.1]
  def change
    create_table :partners do |t|
      t.string :name
      t.string :logo
      t.references :partner_type, foreign_key: true

      t.timestamps
    end
  end
end
