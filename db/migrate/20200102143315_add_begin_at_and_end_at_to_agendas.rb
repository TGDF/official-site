# frozen_string_literal: true

class AddBeginAtAndEndAtToAgendas < ActiveRecord::Migration[5.2]
  def change
    change_table :agendas, bulk: true do |t|
      t.string(:begin_at)
      t.string(:end_at)
    end
  end
end
