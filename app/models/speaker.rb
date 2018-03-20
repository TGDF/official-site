# frozen_string_literal: true

class Speaker < ApplicationRecord
  translates :name, :description

  mount_uploader :avatar, AvatarUploader

  validates :name, :description, :avatar, presence: true
end
