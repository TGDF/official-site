# frozen_string_literal: true

class Game < ApplicationRecord
  translates :name
  translates :description
  translates :team

  mount_uploader :thumbnail, GameThumbnailUploader

  validates :name, :description, :team, :thumbnail, presence: true
end
