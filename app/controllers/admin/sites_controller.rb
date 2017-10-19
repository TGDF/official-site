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
      # TODO: Use permission gem
      allow_fields = %i[name domain tenant_name]
      allow_fields.delete(:tenant_name) if params[:action] == 'update'
      params.require(:site).permit(allow_fields)
    end

    def find_site
      @site = Site.find(params[:id])
    end
  end
end
