# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include TenantSite
  include Localizable

  # TODO: Improve CSRF configuration
  protect_from_forgery except: :render_404

  helper_method :cfp_only?

  layout :layout_by_resource

  def default_url_options(options = {})
    { lang: current_locale }.merge(options)
  end

  def cfp_only?
    current_site.cfp_only_mode == 'true'
  end

  def render_404
    render file: 'public/404.html', status: :not_found, layout: false
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
end
