class Site < ApplicationRecord
  after_create -> { Apartment::Tenant.create(tenant_name) }
  before_destroy -> { Apartment::Tenant.drop(tenant_name) }

  scope :recent, -> { order(updated_at: :desc) }

  def tenant_name
    domain.tr('.', '_')
  end
end
