# frozen_string_literal: true

class PartnerType < ApplicationRecord
  translates :name

  validates :name, presence: true

  default_scope -> { order(order: :asc) }
end
