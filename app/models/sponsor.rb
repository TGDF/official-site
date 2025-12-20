# frozen_string_literal: true

class Sponsor < ApplicationRecord
  include HasMigratedUpload

  acts_as_tenant :site, optional: true

  belongs_to :level, class_name: "SponsorLevel", inverse_of: nil

  translates :name
  translates :description

  mount_uploader :logo, LogoUploader
  has_migrated_upload :logo, variants: ImageVariants::LOGO

  validates :name, presence: true
  validate { errors.add(:logo, :blank) unless logo_present? }

  default_scope -> { order(order: :asc) }
end
