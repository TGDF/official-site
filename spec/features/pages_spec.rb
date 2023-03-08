# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Pages') do
  describe '#index' do
    let!(:news) { create(:news, status: :published) }

    # NOTE: To save_screenshot, should add js: true tag

    it 'shows news' do
      visit root_path
      expect(page).to(have_content(news.title))
    end
  end
end
