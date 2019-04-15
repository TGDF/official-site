# frozen_string_literal: true

module Admin
  class IndieSpacesController < Admin::BaseController
    def edit; end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        if current_site.update(permitted_params)
          return redirect_to edit_admin_indie_space_path
        end

        render :edit
      end
    end

    private

    def permitted_params
      params
        .require(:site)
        .permit(:indie_space_description)
    end
  end
end
