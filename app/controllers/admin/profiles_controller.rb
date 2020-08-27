# frozen_string_literal: true

module Admin
  class ProfilesController < Admin::BaseController
    def edit; end

    def update
      if current_admin_user.update(admin_user_params)
        bypass_sign_in(current_admin_user)
        return redirect_to(admin_root_path)
      end

      render(:edit)
    end

    private

    def admin_user_params
      params.require(:admin_user).permit(:password, :password_confirmation)
    end
  end
end
