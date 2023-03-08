# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::Rooms') do
  let(:admin) { create(:admin_user) }
  let(:room) { create(:room) }

  before { sign_in admin }

  describe '#index' do
    let!(:types) { create_list(:room, 5) }

    it 'can see all types' do
      visit admin_rooms_path
      types.each { |type| expect(page).to(have_content(type.name)) }
    end
  end

  describe '#new' do
    it 'can add new room' do
      visit new_admin_room_path
      fill_in 'room_name', with: 'Example'
      click_button '新增Room'
      expect(page).to(have_content('Example'))
    end
  end

  describe '#edit' do
    let!(:room) { create(:room) }

    it 'can edit room' do
      visit edit_admin_room_path(room)
      fill_in 'room_name', with: 'New room Name'
      click_button '更新Room'
      expect(page).to(have_content('New room Name'))
    end
  end

  describe '#destroy' do
    let!(:room) { create(:room) }

    it 'can destroy room' do
      visit admin_rooms_path

      within first('td', text: room.name).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).not_to(have_content(room.name))
    end
  end
end
