# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Admin::PartnerTypes', type: :feature do
  let(:admin) { create(:admin_user) }
  let(:partner_type) { create(:partner_type) }

  before { sign_in admin }

  describe '#index' do
    before do
      @types = create_list(:partner_type, 5)
    end

    it 'can see all types' do
      visit admin_partner_types_path
      @types.each { |type| expect(page).to have_content(type.name) }
    end
  end
end
