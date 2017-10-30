# frozen_string_literal: true

class SponsorLevel < ApplicationRecord
  validates :name, presence: true

  translates :name
end
