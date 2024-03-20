# frozen_string_literal: true

class AgendaTime < ApplicationRecord
  acts_as_tenant :site, optional: true, has_global_records: true

  has_many :agendas, foreign_key: :time_id, dependent: :nullify,
                     inverse_of: :time
  belongs_to :day, class_name: 'AgendaDay', inverse_of: :times

  validates :label, presence: true

  default_scope -> { order(order: :asc) }

  def name
    "#{day.label} - #{label}"
  end
end
