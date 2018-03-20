# frozen_string_literal: true

class SponsorLevel < ApplicationRecord
  translates :name

  validates :name, presence: true
end
