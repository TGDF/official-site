# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::Profiles', type: :feature) do
  let(:admin) { create(:admin_user) }

  before { sign_in admin }

  describe '#edit' do
    it 'can edit password' do
      visit edit_admin_profile_path
      fill_in 'admin_user_password', with: 'new_password'
      fill_in 'admin_user_password_confirmation', with: 'new_password'
      click_button '更新Admin user'
      expect(page).to(have_content('Dashboard'))
    end
  end
end
