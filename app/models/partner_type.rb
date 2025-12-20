# frozen_string_literal: true

class PartnerType < ApplicationRecord
  acts_as_tenant :site, optional: true

  has_many :partners, foreign_key: "type_id",
                      inverse_of: :type, dependent: :destroy

  translates :name

  validates :name, presence: true

  default_scope -> { order(order: :asc) }

  alias items partners
end
