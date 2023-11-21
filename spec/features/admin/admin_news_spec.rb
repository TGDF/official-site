# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::News') do
  let(:admin) { create(:admin_user) }
  let(:news) { create(:news) }

  before { sign_in admin }

  describe '#index' do
    let!(:news) { create_list(:news, 5) }

    it 'can see all news' do
      visit admin_news_index_path
      news.each { |news| expect(page).to(have_content(news.title)) }
    end
  end

  describe '#new' do
    before do
      visit new_admin_news_path
      fill_in 'news_title', with: 'Example'
      fill_in 'news_slug', with: 'example'
      fill_in 'news_content', with: 'Example Content'
      attach_file(
        'news_thumbnail',
        Rails.root.join('spec/support/brands/logos/TGDF.png')
      )
      click_button '新增News'
    end

    it { expect(page).to(have_content('Example')) }
  end

  describe '#edit' do
    it 'can edit news' do
      visit edit_admin_news_path(news)
      fill_in 'news_title', with: 'New News Name'
      click_button '更新News'
      expect(page).to(have_content('New News Name'))
    end
  end

  describe '#destroy' do
    let!(:news) { create(:news) }

    it 'can destroy news type' do
      visit admin_news_index_path

      within first('td', text: news.title).first(:xpath, './/..') do
        click_button 'Destroy'
      end

      expect(page).not_to(have_content(news.title))
    end
  end

  describe '#preview' do
    it 'can see news in preview mode' do
      visit preview_admin_news_path(news)
      expect(page).to(have_content(news.title))
    end
  end
end
