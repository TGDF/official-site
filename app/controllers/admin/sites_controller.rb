module Admin
  class SitesController < Admin::BaseController
    def index
      @sites = Site.all
    end

    def new
      @site = Site.new
    end

    def create
      @site = Site.new(site_params)
      return redirect_to admin_sites_path if @site.save
      render :new
    end

    protected

    def site_params
      params.require(:site).permit(:name, :domain)
    end
  end
end
