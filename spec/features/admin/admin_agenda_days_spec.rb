# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::AgendaDays') do
  let(:admin) { create(:admin_user) }
  let(:agenda_day) { create(:agenda_day) }

  before { sign_in admin }

  describe '#index' do
    let!(:days) { create_list(:agenda_day, 5) }

    it 'can see all days' do
      visit admin_agenda_days_path
      days.each { |type| expect(page).to(have_content(type.label)) }
    end
  end

  describe '#new' do
    it 'can add new agenda_day' do
      visit new_admin_agenda_day_path
      fill_in 'agenda_day_label', with: 'Example'
      click_on '新增Agenda day'
      expect(page).to(have_content('Example'))
    end
  end

  describe '#edit' do
    let!(:agenda_day) { create(:agenda_day) }

    it 'can edit agenda_day' do
      visit edit_admin_agenda_day_path(agenda_day)
      fill_in 'agenda_day_label', with: 'New agenda_day Label'
      click_on '更新Agenda day'
      expect(page).to(have_content('New agenda_day Label'))
    end
  end

  describe '#destroy' do
    let!(:agenda_day) { create(:agenda_day) }

    it 'can destroy agenda_day' do
      visit admin_agenda_days_path

      within first('td', text: agenda_day.label).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).to(have_no_content(agenda_day.label))
    end
  end
end
