# frozen_string_literal: true

class News < ApplicationRecord
  extend FriendlyId

  acts_as_tenant :site, optional: true, has_global_records: true
  belongs_to :author, polymorphic: true

  translates :title, :content
  friendly_id :title, use: :slugged

  mount_uploader :thumbnail, ThumbnailUploader

  enum status: {
    draft: 0,
    published: 1,
    deleted: 2
  }

  validates :title, :content, :slug, :thumbnail, presence: true
  validates :slug, uniqueness: true

  scope :latest, -> { order(created_at: :desc) }

  default_scope -> { where.not(status: :deleted) }
end
