# frozen_string_literal: true

class News < ApplicationRecord
  belongs_to :author, polymorphic: true

  validates :title, :content, :slug, presence: true
  validates :slug, uniqueness: true

  default_scope -> { where.not(status: :deleted) }

  translates :title, :content

  enum status: {
    draft:     0,
    published: 1,
    deleted:   2
  }
end
