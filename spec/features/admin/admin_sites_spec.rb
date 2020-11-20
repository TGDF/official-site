# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::Sites', type: :feature) do
  let(:admin) { create(:admin_user) }
  let(:site) { create(:site) }

  before do
    Apartment::Tenant.reset
    sign_in admin
  end

  describe '#index' do
    let!(:sites) { create_list(:site, 5) }

    xit 'can see all sites' do
      visit admin_sites_path
      sites.each { |site| expect(page).to(have_content(site.name)) }
    end
  end

  describe '#new' do
    before do
      visit new_admin_site_path
      fill_in 'site_name', with: 'Example'
      fill_in 'site_domain', with: 'example.com'
      fill_in 'site_tenant_name', with: 'example'
      click_button '新增Site'
    end

    xit { expect(page).to(have_content('Example')) }
  end

  describe '#edit' do
    xit 'can edit site' do
      visit edit_admin_site_path(site)
      fill_in 'site_name', with: 'New Site Name'
      click_button '更新Site'
      expect(page).to(have_content('New Site Name'))
    end
  end

  describe '#destroy' do
    let!(:site) { create(:site) }

    xit 'can destroy site type' do
      visit admin_sites_path

      within first('td', text: site.name).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).not_to(have_content(site.name))
    end
  end
end
