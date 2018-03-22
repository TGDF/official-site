# frozen_string_literal: true

module TenantSite
  extend ActiveSupport::Concern

  included do
    helper_method :tenant_site?
    helper_method :current_site
  end

  def current_site
    return default_site unless tenant_site?
    Site.find_by(tenant_name: Apartment::Tenant.current)
  end

  def tenant_site?
    Apartment::Tenant.current != 'public'
  end

  private

  def default_site
    Site.new(
      domain: Settings.site.default_domain,
      name: I18n.t('site_name'),
      tenant_name: 'public'
    )
  end
end
