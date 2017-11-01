# frozen_string_literal: true

class AddTranslationTableForSpeakers < ActiveRecord::Migration[5.1]
  def up
    change_column :speakers, :description, :text

    Speaker.create_translation_table!(
      {
        name: :string,
        description: :text
      },
      migrate_data: true
    )
  end

  def down
    Speaker.drop_translation_table! migrate_data: true
  end
end
