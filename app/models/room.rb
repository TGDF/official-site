# frozen_string_literal: true

class Room < ApplicationRecord
  has_many :agendas, dependent: :nullify

  validates :name, presence: true

  default_scope -> { order(order: :asc) }
end
