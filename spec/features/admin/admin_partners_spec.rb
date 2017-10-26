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
end
