# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::Games', level: :feature) do
  let(:admin) { create(:admin_user) }
  let(:game) { create(:game) }

  before { sign_in admin }

  describe '#index' do
    let!(:games) { create_list(:game, 5) }

    it 'can see all game' do
      visit admin_games_path
      games.each { |game| expect(page).to(have_content(game.name)) }
    end
  end

  describe '#new' do
    before do
      visit new_admin_game_path
      fill_in 'game_name', with: 'Example'
      fill_in 'game_description', with: 'Example Description'
      fill_in 'game_team', with: 'Team'
      attach_file(
        'game_thumbnail',
        Rails.root.join('spec/support/brands/logos/TGDF.png')
      )
      click_button '新增Game'
    end

    it { expect(page).to(have_content('Example')) }
  end

  describe '#edit' do
    it 'can edit game' do
      visit edit_admin_game_path(game)
      fill_in 'game_name', with: 'New Game Name'
      click_button '更新Game'
      expect(page).to(have_content('New Game Name'))
    end
  end

  describe '#destroy' do
    let!(:game) { create(:game) }

    it 'can destroy game' do
      visit admin_games_path

      within first('td', text: game.name).first(:xpath, './/..') do
        click_on 'Destroy'
      end

      expect(page).not_to(have_content(game.name))
    end
  end
end
