class CreateAgendaTimes < ActiveRecord::Migration[5.1]
  def change
    create_table :agenda_times do |t|
      t.string :label
      t.integer :order, null: false, default: 0

      t.timestamps
    end
  end
end
