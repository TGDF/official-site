# frozen_string_literal: true

require 'rails_helper'

RSpec.feature('Admin::Sites', type: :feature) do
  let(:admin) { create(:admin_user) }
  let(:site) { create(:site) }

  before { sign_in admin }

  describe '#index' do
    before do
      @sites = create_list(:site, 5)
    end

    it 'can see all sites' do
      visit admin_sites_path
      @sites.each { |site| expect(page).to(have_content(site.name)) }
    end
  end

  describe '#new' do
    it 'can add new site' do
      visit new_admin_site_path
      fill_in 'site_name', with: 'Example'
      fill_in 'site_domain', with: 'example.com'
      fill_in 'site_tenant_name', with: 'example'
      click_button '新增Site'
      expect(page).to(have_content('Example'))
    end
  end

  describe '#edit' do
    it 'can edit site' do
      visit edit_admin_site_path(site)
      fill_in 'site_name', with: 'New Site Name'
      click_button '更新Site'
      expect(page).to(have_content('New Site Name'))
    end
  end

  describe '#destroy' do
    before { @site = create(:site) }

    it 'can destroy site type' do
      visit admin_sites_path

      within first('td', text: @site.name).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).not_to(have_content(@site.name))
    end
  end
end
