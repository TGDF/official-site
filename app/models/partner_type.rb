# frozen_string_literal: true

class PartnerType < ApplicationRecord
  validates :name, presence: true

  translates :name
end
