# frozen_string_literal: true

class Game < ApplicationRecord
  include HasMigratedUpload

  translates :name
  translates :description
  translates :team

  acts_as_tenant :site, optional: true, has_global_records: true
  mount_uploader :thumbnail, GameThumbnailUploader
  has_migrated_upload :thumbnail, variants: ImageVariants::GAME_THUMBNAIL, validates_presence: { on: :create }

  validates :name, :description, :team, presence: true

  default_scope -> { order(order: :asc) }
end
