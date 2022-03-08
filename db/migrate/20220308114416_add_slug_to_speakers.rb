# frozen_string_literal: true

class AddSlugToSpeakers < ActiveRecord::Migration[5.2]
  def change
    change_table :speakers, bulk: true do |t|
      t.string :slug

      t.index :slug, unique: true
    end
  end
end
