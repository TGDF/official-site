# frozen_string_literal: true

class CreatePlans < ActiveRecord::Migration[7.0]
  def change
    create_table :plans do |t|
      t.jsonb :name, default: {}
      t.jsonb :content, default: {}
      t.jsonb :button_label, default: {}
      t.jsonb :button_target, default: {}

      t.timestamps
    end
  end
end
