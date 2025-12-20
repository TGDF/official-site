# frozen_string_literal: true

class News < ApplicationRecord
  extend FriendlyId
  include HasMigratedUpload

  acts_as_tenant :site, optional: true, has_global_records: true
  belongs_to :author, polymorphic: true

  translates :title, :content
  friendly_id :title, use: :slugged

  mount_uploader :thumbnail, ThumbnailUploader
  has_migrated_upload :thumbnail, variants: ImageVariants::NEWS_THUMBNAIL

  enum :status, {
    draft: 0,
    published: 1,
    deleted: 2
  }

  validates :title, :content, :slug, presence: true
  validate { errors.add(:thumbnail, :blank) unless thumbnail_present? }
  validates :slug, uniqueness: { scope: :site_id }

  scope :latest, -> { order(created_at: :desc) }

  default_scope -> { where.not(status: :deleted) }
end
