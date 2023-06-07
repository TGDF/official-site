# frozen_string_literal: true

module Admin
  class OptionsController < Admin::BaseController
    def edit; end

    def update
      return redirect_to(edit_admin_options_path) if current_site.update(permitted_params)

      render :edit, status: :unprocessable_entity
    end

    private

    def permitted_params
      params
        .require(:site)
        .permit(*SiteOption.attribute_names)
    end
  end
end
