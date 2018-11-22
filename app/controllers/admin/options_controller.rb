# frozen_string_literal: true

module Admin
  class OptionsController < Admin::BaseController
    def edit; end

    def update
      if current_site.update(permitted_params)
        return redirect_to edit_admin_options_path
      end

      render :edit
    end

    private

    def permitted_params
      params
        .require(:site)
        .permit(*Site::TICKET_OPTIONS, :google_analytics_id,
                :cfp_form_url, :cfp_description, :cfp_only_mode,
                :buy_ticket_url, :buy_ticket_opened)
    end
  end
end
