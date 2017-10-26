# frozen_string_literal: true

class PartnerType < ApplicationRecord
  validates :name, presence: true
end
