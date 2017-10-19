module Admin
  class SitesController < Admin::BaseController
    before_action :find_site, only: %i[edit update destroy]

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

    def edit; end

    def update
      return redirect_to admin_sites_path if @site.update(site_params)
      render :edit
    end

    protected

    def site_params
      params.require(:site).permit(:name, :domain)
    end

    def find_site
      @site = Site.find(params[:id])
    end
  end
end
