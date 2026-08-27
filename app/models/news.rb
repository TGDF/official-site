# frozen_string_literal: true

class News < ApplicationRecord
  extend FriendlyId
  include HasMigratedUpload

  acts_as_tenant :site, optional: true, has_global_records: true
  belongs_to :author, polymorphic: true

  translates :title, :content
  friendly_id :title, use: :slugged

  mount_uploader :thumbnail, ThumbnailUploader
  has_migrated_upload :thumbnail, variants: ImageVariants::NEWS_THUMBNAIL, validates_presence: true

  enum :status, {
    draft: 0,
    published: 1,
    deleted: 2
  }

  validates :title, :content, :slug, presence: true
  # Not plain `uniqueness: { scope: :site_id }`: while `has_global_records` is on, this
  # also checks a row that has a `site_id` against the rows that do not, and six of the
  # nine tenants carry null on every row. Without that reach, a new item could take a
  # slug a legacy row already holds, and `consolidate[news]` — which gives both the same
  # `site_id` — would then hit the unique index and roll the tenant back.
  validates_uniqueness_to_tenant :slug

  scope :latest, -> { order(created_at: :desc) }

  default_scope -> { where.not(status: :deleted) }
end
