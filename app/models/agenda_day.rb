# frozen_string_literal: true

class AgendaDay < ApplicationRecord
  acts_as_tenant :site, optional: true

  has_many :times, class_name: "AgendaTime", inverse_of: :day,
                   dependent: :destroy, foreign_key: :day_id

  validates :label, presence: true

  def name
    "#{label} (#{date})"
  end
end
