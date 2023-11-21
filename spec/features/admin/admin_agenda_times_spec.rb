# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::AgendaTimes') do
  let(:admin) { create(:admin_user) }
  let(:agenda_time) { create(:agenda_time) }

  before { sign_in admin }

  describe '#index' do
    let!(:times) { create_list(:agenda_time, 5) }

    it 'can see all times' do
      visit admin_agenda_times_path
      times.each { |type| expect(page).to(have_content(type.label)) }
    end
  end

  describe '#new' do
    let!(:agenda_day) { create(:agenda_day) }

    it 'can add new agenda_time' do
      visit new_admin_agenda_time_path
      fill_in 'agenda_time_label', with: 'Example'
      select agenda_day.name, from: 'agenda_time_day_id'
      click_button '新增Agenda time'
      expect(page).to(have_content('Example'))
    end
  end

  describe '#edit' do
    let!(:agenda_time) { create(:agenda_time) }

    it 'can edit agenda_time' do
      visit edit_admin_agenda_time_path(agenda_time)
      fill_in 'agenda_time_label', with: 'New agenda_time Label'
      click_button '更新Agenda time'
      expect(page).to(have_content('New agenda_time Label'))
    end
  end

  describe '#destroy' do
    let!(:agenda_time) { create(:agenda_time) }

    it 'can destroy agenda_time' do
      visit admin_agenda_times_path

      within first('td', text: agenda_time.label).first(:xpath, './/..') do
        click_button 'Destroy'
      end

      expect(page).not_to(have_content(agenda_time.label))
    end
  end
end
