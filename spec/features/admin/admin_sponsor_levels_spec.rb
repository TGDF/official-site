# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Admin::SponsorLevels', type: :feature do
  let(:admin) { create(:admin_user) }
  let(:sponsor_level) { create(:sponsor_level) }

  before { sign_in admin }

  describe '#index' do
    before do
      @types = create_list(:sponsor_level, 5)
    end

    it 'can see all types' do
      visit admin_sponsor_levels_path
      @types.each { |type| expect(page).to have_content(type.name) }
    end
  end
end
