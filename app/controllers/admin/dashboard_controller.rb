# frozen_string_literal: true

module Admin
  class DashboardController < Admin::BaseController
    skip_before_action :require_tenant_site!

    def index; end
  end
end
