class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  layout :layout_by_resource

  helper_method :tenant_site?

  def tenant_site?
    Apartment::Tenant.current != 'public'
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
