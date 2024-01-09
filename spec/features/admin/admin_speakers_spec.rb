# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::Speakers') do
  let(:admin) { create(:admin_user) }
  let(:speaker) { create(:speaker) }

  before { sign_in admin }

  describe '#index' do
    let!(:speakers) { create_list(:speaker, 5) }

    it 'can see all speaker' do
      visit admin_speakers_path
      speakers.each { |speaker| expect(page).to(have_content(speaker.name)) }
    end
  end

  describe '#new' do
    before do
      visit new_admin_speaker_path
      fill_in 'speaker_name', with: 'Example'
      fill_in 'speaker_description', with: 'Example Content'
      attach_file(
        'speaker_avatar',
        Rails.root.join('spec/support/avatars/Aotoki.jpg')
      )
      click_on '新增Speaker'
    end

    it { expect(page).to(have_content('Example')) }
  end

  describe '#edit' do
    it 'can edit speaker' do
      visit edit_admin_speaker_path(speaker)
      fill_in 'speaker_name', with: 'New speaker Name'
      click_on '更新Speaker'
      expect(page).to(have_content('New speaker Name'))
    end
  end

  describe '#destroy' do
    let!(:speaker) { create(:speaker) }

    it 'can destroy speaker' do
      visit admin_speakers_path

      within first('td', text: speaker.name).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).to(have_no_content(speaker.name))
    end
  end
end
