class CreateAgendas < ActiveRecord::Migration[5.1]
  def change
    create_table :agendas do |t|
      t.string :subject
      t.text :description

      t.timestamps
    end
  end
end
