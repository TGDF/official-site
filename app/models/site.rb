# frozen_string_literal: true

class Site < ApplicationRecord
  translates :name, :description, :indie_space_description

  mount_uploader :logo, SiteLogoUploader
  mount_uploader :figure, SiteFigureUploader

  SiteOption.each do |option|
    store_attribute :options, option[:name], option[:type]
  end

  validates :name, :domain, :tenant_name, presence: true
  validates :domain, format: /\A[a-z0-9]+([-.]{1}[a-z0-9]+)*\.[a-z]+\z/ix
  validates :tenant_name, format: /\A[a-z0-9]+([_a-z0-9]+)*[a-z0-9]+\z/ix

  scope :recent, -> { order(updated_at: :desc) }
  default_scope -> { order(created_at: :desc) }

  after_create -> { Apartment::Tenant.create(tenant_name) }
  before_destroy -> { Apartment::Tenant.drop(tenant_name) }
end
