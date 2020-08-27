# frozen_string_literal: true

class AddIntervalToSliders < ActiveRecord::Migration[5.1]
  def change
    add_column(:sliders, :interval, :integer, default: 5000)
  end
end
