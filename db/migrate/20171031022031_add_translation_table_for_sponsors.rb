# frozen_string_literal: true

class AddTranslationTableForSponsors < ActiveRecord::Migration[5.1]
  def up
    Sponsor.create_translation_table!(
      {
        name: :string
      },
      migrate_data: true
    )
  end

  def down
    Sponsor.drop_translation_table! migrate_data: true
  end
end
