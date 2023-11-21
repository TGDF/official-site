# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::Sites') do
  let(:admin) { create(:admin_user) }
  let(:site) { create(:site) }

  before do
    Apartment::Tenant.reset
    sign_in admin
  end

  describe '#index' do
    let!(:sites) { create_list(:site, 5) }

    it 'can see all sites', pending: 'root tentant not resloved' do
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

    it 'is expected to create a new site', pending: 'root tentant not resloved' do
      expect(page).to(have_content('Example'))
    end
  end

  describe '#edit' do
    it 'can edit site', pending: 'root tentant not resloved' do
      visit edit_admin_site_path(site)
      fill_in 'site_name', with: 'New Site Name'
      click_button '更新Site'
      expect(page).to(have_content('New Site Name'))
    end
  end

  describe '#destroy' do
    let!(:site) { create(:site) }

    it 'can destroy site type', pending: 'root tentant not resloved' do
      visit admin_sites_path

      within first('td', text: site.name).first(:xpath, './/..') do
        click_button 'Destroy'
      end

      expect(page).not_to(have_content(site.name))
    end
  end
end
