# frozen_string_literal: true

module Admin
  class BaseController < ::ApplicationController
    before_action do
      request.variant = :v1 if admin_v1_legacy_enabled?
    end
    before_action :authenticate_admin_user!
    before_action -> { @navbar_sites = Site.recent.limit(5) }

    helper_method :admin_current_resource_locale
    helper_method :admin_v1_legacy_enabled?

    def admin_current_resource_locale
      save_admin_resource_locale

      (([ cookies[:resource_locale]&.to_sym ] & I18n.available_locales).first ||
       I18n.default_locale).to_s
    end

    def admin_v1_legacy_enabled?
      Flipper.enabled?(:admin_v1_legacy, current_admin_user)
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
  end
end
