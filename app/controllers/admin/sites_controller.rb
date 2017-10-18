module Admin
  class SitesController < Admin::BaseController
    def index
      @sites = Site.all
    end
  end
end
