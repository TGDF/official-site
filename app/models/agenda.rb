# frozen_string_literal: true

class Agenda < ApplicationRecord
  translates :subject, :description

  has_many :agendas_speakers, dependent: :destroy
  has_many :speakers, through: :agendas_speakers

  belongs_to :time, class_name: 'AgendaTime', foreign_key: :time_id,
                    inverse_of: :agendas, optional: true
  belongs_to :room, optional: true

  validates :subject, :description, presence: true
end
