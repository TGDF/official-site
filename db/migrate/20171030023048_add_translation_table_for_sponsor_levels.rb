# frozen_string_literal: true

class AddTranslationTableForSponsorLevels < ActiveRecord::Migration[5.1]
  def up
    SponsorLevel.create_translation_table!(
      {
        name: :string
      },
      migrate_data: true
    )
  end

  def down
    SponsorLevel.drop_translation_table! migrate_data: true
  end
end
