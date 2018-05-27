# frozen_string_literal: true

class Agenda < ApplicationRecord
  translates :subject, :description

  has_many :agendas_speakers, dependent: :destroy
  has_many :speakers, through: :agendas_speakers

  validates :subject, :description, presence: true
end
