module Admin
  class BaseController < ::ApplicationController
    before_action :authenticate_admin_user!
    before_action -> { @navbar_sites = Site.recent.limit(5) }
  end
end
