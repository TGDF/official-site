# frozen_string_literal: true

class Speaker < ApplicationRecord
  extend FriendlyId
  include HasMigratedUpload

  acts_as_tenant :site, optional: true, has_global_records: true
  translates :name, :title, :description
  friendly_id :name, use: :slugged

  mount_uploader :avatar, AvatarUploader
  has_migrated_upload :avatar, variants: ImageVariants::AVATAR, validates_presence: true

  has_many :agendas_speakers, dependent: :destroy
  has_many :agendas, through: :agendas_speakers

  default_scope -> { order(order: :asc) }

  validates :name, :slug, :description, presence: true
  # Not plain `uniqueness: { scope: :site_id }`: while `has_global_records` is on, this
  # also covers the rows the composite index cannot — six of the nine tenants carry a
  # null `site_id`, and PostgreSQL treats nulls as distinct. The extra cover falls away
  # on its own once the group is consolidated and the flag is removed.
  validates_uniqueness_to_tenant :slug
end
