# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include TenantSite

  protect_from_forgery with: :exception

  layout :layout_by_resource

  before_action :set_locale

  helper_method :current_locale

  def default_url_options(options = {})
    { locale: cookies[:locale] }.merge(options)
  end

  def current_locale
    ([params[:locale]] & Settings.locales).first || I18n.default_locale.to_s
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

  def set_locale
    cookies[:locale] = current_locale if params[:locale]
    cookies.delete(:locale) if params[:locale] == I18n.default_locale.to_s
    I18n.locale = cookies[:locale] || current_locale
  end
end
