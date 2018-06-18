# frozen_string_literal: true

class AgendaDay < ApplicationRecord
  validates :label, presence: true
end
