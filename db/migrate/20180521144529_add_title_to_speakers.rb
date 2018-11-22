# frozen_string_literal: true

class AddTitleToSpeakers < ActiveRecord::Migration[5.1]
  def change
    add_column :speakers, :title, :jsonb
  end
end
