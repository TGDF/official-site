# frozen_string_literal: true

class Sponsor < ApplicationRecord
  belongs_to :level, class_name: 'SponsorLevel', inverse_of: nil

  translates :name

  mount_uploader :logo, LogoUploader

  validates :name, :logo, presence: true

  default_scope -> { order(order: :asc) }
end
