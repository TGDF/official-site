# frozen_string_literal: true

class Game < ApplicationRecord
  include HasMigratedUpload

  translates :name
  translates :description
  translates :team

  acts_as_tenant :site, optional: true, has_global_records: true
  mount_uploader :thumbnail, GameThumbnailUploader
  has_migrated_upload :thumbnail, variants: ImageVariants::GAME_THUMBNAIL

  validates :name, :description, :team, presence: true
  validate on: :create do
    errors.add(:thumbnail, :blank) unless thumbnail_present?
  end

  default_scope -> { order(order: :asc) }
end
