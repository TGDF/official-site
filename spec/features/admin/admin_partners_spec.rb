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
end
