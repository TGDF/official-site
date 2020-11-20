# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::Options', level: :feature) do
  let(:admin) { create(:admin_user) }
  let(:site) { create(:site) }

  before do
    sign_in admin
    Apartment::Tenant.switch!(site.tenant_name)
  end

  after do
    Apartment::Tenant.reset
  end

  describe '#edit' do
    it 'can edit ste options' do
      visit edit_admin_options_path
      fill_in 'site_ticket_personal_price', with: '1500'
      click_button '更新Site', match: :first
      # TODO: Improve check to ensure correct field is shown
      visit root_path
      expect(page).to(have_content('1500'))
    end
  end
end
