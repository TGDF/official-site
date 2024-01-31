# frozen_string_literal: true

class Game < ApplicationRecord
  translates :name
  translates :description
  translates :team

  acts_as_tenant :site, optional: true, has_global_records: true
  mount_uploader :thumbnail, GameThumbnailUploader

  validates :name, :description, :team, presence: true
  validates :thumbnail, presence: true, on: :create

  default_scope -> { order(order: :asc) }
end
