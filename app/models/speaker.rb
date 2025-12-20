# frozen_string_literal: true

class Speaker < ApplicationRecord
  extend FriendlyId
  include HasMigratedUpload

  acts_as_tenant :site, optional: true, has_global_records: true
  translates :name, :title, :description
  friendly_id :name, use: :slugged

  mount_uploader :avatar, AvatarUploader
  has_migrated_upload :avatar, variants: ImageVariants::AVATAR

  has_many :agendas_speakers, dependent: :destroy
  has_many :agendas, through: :agendas_speakers

  default_scope -> { order(order: :asc) }

  validates :name, :slug, :description, presence: true
  validate :avatar_must_be_present

  private

  def avatar_must_be_present
    return if avatar_present?

    errors.add(:avatar, :blank)
  end
end
