# frozen_string_literal: true

class Speaker < ApplicationRecord
  translates :name, :description

  validates :name, :description, :avatar, presence: true
end
