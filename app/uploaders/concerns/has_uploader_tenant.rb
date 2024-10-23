# frozen_string_literal: true

module HasUploaderTenant
  extend ActiveSupport::Concern

  def tenant_name
    ActsAsTenant.current_tenant&.tenant_name || 'default'
  end
end
