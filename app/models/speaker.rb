# frozen_string_literal: true

class Speaker < ApplicationRecord
  validates :name, :description, :avatar, presence: true
end
