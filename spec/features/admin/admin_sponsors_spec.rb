# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::Sponsors', level: :feature) do
  let(:admin) { create(:admin_user) }
  let(:sponsor) { create(:sponsor) }

  before { sign_in admin }

  describe '#index' do
    let!(:sponsors) { create_list(:sponsor, 5) }

    it 'can see all sponsor' do
      visit admin_sponsors_path
      sponsors.each { |sponsor| expect(page).to(have_content(sponsor.name)) }
    end
  end

  describe '#new' do
    let!(:level) { create(:sponsor_level) }

    before do
      visit new_admin_sponsor_path
      fill_in 'sponsor_name', with: 'Example'
      attach_file('sponsor_logo', Rails.root.join('spec/support/brands/logos/TGDF.png'))
      select level.name, from: 'sponsor_level_id'
      click_on '新增Sponsor'
    end

    it { expect(page).to(have_content('Example')) }
  end

  describe '#edit' do
    it 'can edit sponsor' do
      visit edit_admin_sponsor_path(sponsor)
      fill_in 'sponsor_name', with: 'New sponsor Name'
      click_on '更新Sponsor'
      expect(page).to(have_content('New sponsor Name'))
    end
  end

  describe '#destroy' do
    let!(:sponsor) { create(:sponsor) }

    it 'can destroy sponsor' do
      visit admin_sponsors_path

      within first('td', text: sponsor.name).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).to(have_no_content(sponsor.name))
    end
  end
end
