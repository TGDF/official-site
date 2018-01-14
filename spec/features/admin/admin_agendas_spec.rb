# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Admin::Agendas', type: :feature do
  let(:admin) { create(:admin_user) }
  let(:agenda) { create(:agenda) }

  before { sign_in admin }

  describe '#index' do
    before do
      @agendas = create_list(:agenda, 5)
    end

    it 'can see all agenda' do
      visit admin_agendas_path
      @agendas.each { |agenda| expect(page).to have_content(agenda.subject) }
    end
  end

  describe '#new' do
    it 'can add new agenda' do
      visit new_admin_agenda_path
      fill_in 'agenda_subject', with: 'Example'
      fill_in 'agenda_description', with: 'Example Content'
      click_button '新增Agenda'
      expect(page).to have_content('Example')
    end
  end

  describe '#edit' do
    it 'can edit agenda' do
      visit edit_admin_agenda_path(agenda)
      fill_in 'agenda_subject', with: 'New agenda Name'
      click_button '更新Agenda'
      expect(page).to have_content('New agenda Name')
    end
  end

  describe '#destroy' do
    before { @agenda = create(:agenda) }

    it 'can destroy agenda' do
      visit admin_agendas_path

      within first('td', text: @agenda.subject).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).not_to have_content(@agenda.subject)
    end
  end
end
