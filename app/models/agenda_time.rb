# frozen_string_literal: true

class AgendaTime < ApplicationRecord
  validates :label, presence: true

  default_scope -> { order(order: :asc) }
end
