# frozen_string_literal: true

class AddTranslationTableForPartners < ActiveRecord::Migration[5.1]
  def up
    Partner.create_translation_table!(
      {
        name: :string
      },
      migrate_data: true
    )
  end

  def down
    Partner.drop_translation_table! migrate_data: true
  end
end
