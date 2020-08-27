# frozen_string_literal: true

require 'rails_helper'

RSpec.feature('Admin::SponsorLevels', type: :feature) do
  let(:admin) { create(:admin_user) }
  let(:sponsor_level) { create(:sponsor_level) }

  before { sign_in admin }

  describe '#index' do
    before do
      @types = create_list(:sponsor_level, 5)
    end

    it 'can see all types' do
      visit admin_sponsor_levels_path
      @types.each { |type| expect(page).to(have_content(type.name)) }
    end
  end

  describe '#new' do
    it 'can add new sponsor level' do
      visit new_admin_sponsor_level_path
      fill_in 'sponsor_level_name', with: 'Example'
      click_button '新增Sponsor level'
      expect(page).to(have_content('Example'))
    end
  end

  describe '#edit' do
    before { @level = create(:sponsor_level) }

    it 'can edit sponsor level' do
      visit edit_admin_sponsor_level_path(@level)
      fill_in 'sponsor_level_name', with: 'New Level Name'
      click_button '更新Sponsor level'
      expect(page).to(have_content('New Level Name'))
    end
  end

  describe '#destroy' do
    before { @level = create(:sponsor_level) }

    it 'can destroy sponsor level' do
      visit admin_sponsor_levels_path

      within first('td', text: @level.name).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).not_to(have_content(@level.name))
    end
  end
end
