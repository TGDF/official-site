# frozen_string_literal: true

class Sponsor < ApplicationRecord
  belongs_to :level, class_name: 'SponsorLevel', inverse_of: nil

  # FIXME: If globalize for rails 5 is ready, prevent to add `attribute`
  attribute :name
  translates :name

  mount_uploader :logo, LogoUploader

  validates :name, :logo, presence: true
end
