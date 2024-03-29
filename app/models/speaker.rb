# frozen_string_literal: true

class Speaker < ApplicationRecord
  extend FriendlyId

  acts_as_tenant :site, optional: true, has_global_records: true
  translates :name, :title, :description
  friendly_id :name, use: :slugged

  mount_uploader :avatar, AvatarUploader

  has_many :agendas_speakers, dependent: :destroy
  has_many :agendas, through: :agendas_speakers

  default_scope -> { order(order: :asc) }

  validates :name, :slug, :description, :avatar, presence: true
end
