# frozen_string_literal: true

class News < ApplicationRecord
  belongs_to :author, polymorphic: true

  # FIXME: If globalize for rails 5 is ready, prevent to add `attribute`
  attribute :title
  attribute  :content
  translates :title, :content

  mount_uploader :thumbnail, ThumbnailUploader

  enum status: {
    draft:     0,
    published: 1,
    deleted:   2
  }

  validates :title, :content, :slug, :thumbnail, presence: true
  validates :slug, uniqueness: true

  default_scope -> { where.not(status: :deleted) }
end
