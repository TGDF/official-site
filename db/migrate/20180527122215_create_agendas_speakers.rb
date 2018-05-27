class CreateAgendasSpeakers < ActiveRecord::Migration[5.1]
  def change
    create_table :agendas_speakers do |t|
      t.references :agenda, foreign_key: true
      t.references :speaker, foreign_key: true

      t.timestamps
    end
  end
end
