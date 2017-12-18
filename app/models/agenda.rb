# frozen_string_literal: true

class Agenda < ApplicationRecord
  # FIXME: If globalize for rails 5 is ready, prevent to add `attribute`
  attribute :subject
  attribute :description
  translates :subject, :description

  validates :subject, :description, presence: true
end
