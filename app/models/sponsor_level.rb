# frozen_string_literal: true

class SponsorLevel < ApplicationRecord
  translates :name

  has_many :sponsors, dependent: :destroy, foreign_key: :level_id,
                      inverse_of: :level

  validates :name, presence: true

  default_scope -> { order(order: :asc) }
end
