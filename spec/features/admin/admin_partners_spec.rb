# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Admin::Partners', type: :feature do
  let(:admin) { create(:admin_user) }
  let(:partner) { create(:partner) }

  before { sign_in admin }

  describe '#index' do
    before do
      @partners = create_list(:partner, 5)
    end

    it 'can see all partner' do
      visit admin_partners_path
      @partners.each { |partner| expect(page).to have_content(partner.name) }
    end
  end

  describe '#new' do
    let!(:type) { create(:partner_type) }

    it 'can add new partner' do
      visit new_admin_partner_path
      fill_in 'partner_name', with: 'Example'
      attach_file(
        'partner_logo',
        Rails.root.join('spec', 'support', 'brands', 'logos', 'TGDF.png')
      )
      select type.name, from: 'partner_type_id'
      click_button '新增Partner'
      expect(page).to have_content('Example')
    end
  end

  describe '#edit' do
    it 'can edit partner' do
      visit edit_admin_partner_path(partner)
      fill_in 'partner_name', with: 'New Partner Name'
      click_button '更新Partner'
      expect(page).to have_content('New Partner Name')
    end
  end

  describe '#destroy' do
    before { @partner = create(:partner) }

    it 'can destroy partner' do
      visit admin_partners_path

      within first('td', text: @partner.name).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).not_to have_content(@partner.name)
    end
  end
end
