# frozen_string_literal: true

class CreateAgendasTaggings < ActiveRecord::Migration[5.1]
  def change
    create_table :agendas_taggings do |t|
      t.bigint(:agenda_id)
      t.bigint(:agenda_tag_id)

      t.timestamps
    end
  end
end
