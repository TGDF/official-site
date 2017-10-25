class CreatePartnerTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :partner_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
