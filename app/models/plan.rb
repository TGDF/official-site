# frozen_string_literal: true

class Plan < ApplicationRecord
  translates :name, :content, :button_label, :button_target

  validates :name, presence: true
end
