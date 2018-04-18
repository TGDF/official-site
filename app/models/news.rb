# frozen_string_literal: true

class News < ApplicationRecord
  belongs_to :author, polymorphic: true

  translates :title, :content

  mount_uploader :thumbnail, ThumbnailUploader

  enum status: {
    draft:     0,
    published: 1,
    deleted:   2
  }

  validates :title, :content, :slug, :thumbnail, presence: true
  validates :slug, uniqueness: true

  scope :latest, -> { order(created_at: :desc) }

  default_scope -> { where.not(status: :deleted) }
end
