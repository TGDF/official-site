# frozen_string_literal: true

class AddLanguageToAgendas < ActiveRecord::Migration[5.1]
  def change
    change_table :agendas, bulk: true do |t|
      t.integer(:language)
      t.integer(:translated_language, null: true)
      t.integer(:translated_type, null: true)
    end
  end
end
