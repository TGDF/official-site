# frozen_string_literal: true

class AgendaDay < ApplicationRecord
  has_many :times, class_name: 'AgendaTime', inverse_of: :day,
                   dependent: :destroy

  validates :label, presence: true

  def name
    "#{label} (#{date})"
  end
end
