# frozen_string_literal: true

module Admin
  class BaseController < ::ApplicationController
    before_action :authenticate_admin_user!
    before_action :require_tenant_site!
    before_action -> { @navbar_sites = Site.recent.limit(5) }

    helper_method :admin_current_resource_locale

    def admin_current_resource_locale
      save_admin_resource_locale

      (([ cookies[:resource_locale]&.to_sym ] & I18n.available_locales).first ||
       I18n.default_locale).to_s
    end

    def ensure_site_created!; end

    private

    def require_tenant_site!
      return if tenant_site?

      redirect_to admin_root_path, alert: t("admin.errors.tenant_only")
    end

    def save_admin_resource_locale
      return if params[:resource_locale].blank?

      cookies[:resource_locale] = params[:resource_locale]
    end
  end
end
