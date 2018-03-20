# frozen_string_literal: true

class Agenda < ApplicationRecord
  translates :subject, :description

  validates :subject, :description, presence: true
end
