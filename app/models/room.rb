# frozen_string_literal: true

class Room < ApplicationRecord
  acts_as_tenant :site, optional: true

  has_many :agendas, dependent: :nullify

  validates :name, presence: true

  default_scope -> { order(order: :asc) }
end
