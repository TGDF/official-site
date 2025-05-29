# frozen_string_literal: true

module Admin
  class BaseController < ::ApplicationController
    before_action do
      request.variant = :v2 if enable_admin_v2?
    end
    before_action :authenticate_admin_user!
    before_action -> { @navbar_sites = Site.recent.limit(5) }

    helper_method :admin_current_resource_locale

    def admin_current_resource_locale
      save_admin_resource_locale

      (([ cookies[:resource_locale]&.to_sym ] & I18n.available_locales).first ||
       I18n.default_locale).to_s
    end

    def ensure_site_created!
      return if current_site.domain == request.host

      redirect_to admin_root_url(host: Settings.site.default_domain), allow_other_host: true
    end

    private

    def save_admin_resource_locale
      return if params[:resource_locale].blank?

      cookies[:resource_locale] = params[:resource_locale]
    end

    def enable_admin_v2?
      params[:variant] == "v2" || Flipper.enabled?(:admin_v2, current_admin_user)
    end
  end
end
