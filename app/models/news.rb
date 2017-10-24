# frozen_string_literal: true

class News < ApplicationRecord
  belongs_to :author, polymorphic: true

  default_scope -> { where.not(status: :deleted) }

  enum status: {
    draft:     0,
    published: 1,
    deleted:   2
  }

  validates :title, :content, :slug, presence: true
  validates :slug, uniqueness: true
end
