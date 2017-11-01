# frozen_string_literal: true

class Speaker < ApplicationRecord
  # FIXME: If globalize for rails 5 is ready, prevent to add `attribute`
  attribute :name
  attribute :description
  translates :name, :description

  mount_uploader :logo, LogoUploader

  validates :name, :description, :avatar, presence: true
end
