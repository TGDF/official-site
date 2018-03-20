class CreateAgendas < ActiveRecord::Migration[5.1]
  def change
    create_table :agendas do |t|
      t.jsonb :subject, default: {}
      t.jsonb :description, default: {}

      t.timestamps
    end
  end
end
