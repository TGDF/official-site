# frozen_string_literal: true

class Partner < ApplicationRecord
  belongs_to :type, class_name: 'PartnerType'

  translates :name
  mount_uploader :logo, LogoUploader

  validates :name, :logo, presence: true
end
