# frozen_string_literal: true

class Partner < ApplicationRecord
  belongs_to :type, class_name: 'PartnerType', inverse_of: nil

  translates :name
  translates :description

  mount_uploader :logo, LogoUploader

  validates :name, :logo, presence: true

  default_scope -> { order(order: :asc) }
end
