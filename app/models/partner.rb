# frozen_string_literal: true

class Partner < ApplicationRecord
  belongs_to :type, class_name: 'PartnerType'

  validates :name, :logo, presence: true
end
