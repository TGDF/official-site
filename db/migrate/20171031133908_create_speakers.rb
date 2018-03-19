class CreateSpeakers < ActiveRecord::Migration[5.1]
  def change
    create_table :speakers do |t|
      t.jsonb :name, default: {}
      t.jsonb :description, default: {}
      t.string :avatar

      t.timestamps
    end
  end
end
