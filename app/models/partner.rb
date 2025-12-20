# frozen_string_literal: true

class Partner < ApplicationRecord
  include HasMigratedUpload

  acts_as_tenant :site, optional: true

  belongs_to :type, class_name: "PartnerType", inverse_of: nil

  translates :name
  translates :description

  mount_uploader :logo, LogoUploader
  has_migrated_upload :logo, variants: ImageVariants::LOGO

  validates :name, presence: true
  validate { errors.add(:logo, :blank) unless logo_present? }

  default_scope -> { order(order: :asc) }
end
