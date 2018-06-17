# frozen_string_literal: true

class Room < ApplicationRecord
  validates :name, present: true

  default_scope -> { order(order: :asc) }
end
