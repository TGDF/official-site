# frozen_string_literal: true

module TenantSite
  extend ActiveSupport::Concern

  included do
    set_current_tenant_through_filter
    before_action :set_tenant

    helper_method :tenant_site?
    helper_method :current_site
  end

  def set_tenant
    return nil if request.host.blank?

    site = Site.find_by(domain: request.host)
    set_current_tenant(site) if site.present?
  end

  def current_site
    return default_site unless tenant_site?

    @current_site ||= Site.find_by(tenant_name: Apartment::Tenant.current)
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
