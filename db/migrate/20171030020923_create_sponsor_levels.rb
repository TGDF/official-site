class CreateSponsorLevels < ActiveRecord::Migration[5.1]
  def change
    create_table :sponsor_levels do |t|
      t.string :name

      t.timestamps
    end
  end
end
