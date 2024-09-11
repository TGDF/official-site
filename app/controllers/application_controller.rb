# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include TenantSite
  include Localizable
  include Previewable
  include NavigationItem

  before_action :ensure_site_created!
  after_action :track_current_site

  protect_from_forgery

  helper_method :cfp_only?

  layout :layout_by_resource

  # TODO: Create 404 page with common style
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def default_url_options(options = {})
    { lang: current_locale }.merge(options)
  end

  def cfp_only?
    current_site.cfp_only_mode?
  end

  # TODO: Use Rails to handler errors
  def not_found
    render(file: 'public/404.html', status: :not_found, layout: false)
  end

  def ensure_site_created!
    return if current_site.domain == request.host

    redirect_to root_url(host: Settings.site.default_domain), allow_other_host: true
  end

  private

  def layout_by_resource
    return 'admin_login' if devise_admin_user_controller?
    return 'admin' if admin_portal?

    'application'
  end

  def devise_admin_user_controller?
    devise_controller? && resource_name == :admin_user
  end

  def admin_portal?
    params[:controller].start_with?('admin/')
  end

  def track_current_site
    logger.debug("Apartment: #{Apartment::Tenant.current}")
    logger.debug("ActsAsTenant: #{ActsAsTenant.current_tenant&.tenant_name}")
  end
end
