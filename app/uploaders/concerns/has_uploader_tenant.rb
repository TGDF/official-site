# frozen_string_literal: true

module HasUploaderTenant
  extend ActiveSupport::Concern

  def tenant_name
    ActsAsTenant.current_tenant&.tenant_name || Apartment::Tenant.current
  end
end
