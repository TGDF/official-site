# frozen_string_literal: true

class AddTranslationTableForPartnerTypes < ActiveRecord::Migration[5.1]
  def up
    PartnerType.create_translation_table!(
      {
        name: :string
      },
      migrate_data: true
    )
  end

  def down
    PartnerType.drop_translation_table! migrate_data: true
  end
end
