# frozen_string_literal: true

class SponsorLevel < ApplicationRecord
  # FIXME: If globalize for rails 5 is ready, prevent to add `attribute`
  attribute :name
  translates :name

  validates :name, presence: true
end
