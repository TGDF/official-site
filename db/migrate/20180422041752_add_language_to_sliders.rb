# frozen_string_literal: true

class AddLanguageToSliders < ActiveRecord::Migration[5.1]
  def change
    add_column :sliders, :language, :integer, default: 0, null: false
  end
end
