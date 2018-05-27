# frozen_string_literal: true

class Speaker < ApplicationRecord
  translates :name, :title, :description

  mount_uploader :avatar, AvatarUploader

  has_many :agendas_speakers, dependent: :destroy
  has_many :agendas, through: :agendas_speakers

  validates :name, :description, :avatar, presence: true
end
