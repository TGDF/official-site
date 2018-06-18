# frozen_string_literal: true

class AgendaTime < ApplicationRecord
  has_many :agendas, dependent: :nullify
  belongs_to :day, class_name: 'AgendaDay', inverse_of: :times

  validates :label, presence: true

  default_scope -> { order(order: :asc) }

  def name
    "#{day.label} - #{label}"
  end
end
