# frozen_string_literal: true

class Game < ApplicationRecord
  translates :name
  translates :description
  translates :team

  mount_uploader :thumbnail, GameThumbnailUploader

  validates :name, :description, :team, presence: true
  validates :thumbnail, presence: true, on: :create

  default_scope -> { order(order: :asc) }
end
