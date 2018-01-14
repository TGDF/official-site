class AddTranslationTableForAgendas < ActiveRecord::Migration[5.1]
  def up
    Agenda.create_translation_table!(
      {
        subject: :string,
        description: :text
      },
      migrate_data: true
    )
  end

  def down
    Agenda.drop_translation_table! migrate_data: true
  end
end
