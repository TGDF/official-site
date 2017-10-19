class Site < ApplicationRecord
  after_create -> { Apartment::Tenant.create(tenant_name) }
  before_destroy -> { Apartment::Tenant.drop(tenant_name) }

  validates :name, :domain, presence: true
  validates :domain, format: /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]+\z/ix

  scope :recent, -> { order(updated_at: :desc) }
  default_scope -> { order(created_at: :desc) }

  def tenant_name
    domain.tr('.', '_')
  end
end
