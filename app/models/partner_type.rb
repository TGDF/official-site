# frozen_string_literal: true

class PartnerType < ApplicationRecord
  translates :name

  validates :name, presence: true
end
