# frozen_string_literal: true

require 'rails_helper'

RSpec.describe('Admin::IndieSpace::Games', level: :feature) do
  let(:admin) { create(:admin_user) }
  let(:game) { create(:game, type: 'IndieSpace::Game') }

  before { sign_in admin }

  describe '#index' do
    let!(:games) { create_list(:game, 5, type: 'IndieSpace::Game') }

    it 'can see all game' do
      visit admin_indie_space_games_path
      games.each { |game| expect(page).to(have_content(game.name)) }
    end
  end

  describe '#new' do
    before do
      visit new_admin_indie_space_game_path
      fill_in 'indie_space_game_name', with: 'Example'
      fill_in 'indie_space_game_description', with: 'Example Description'
      fill_in 'indie_space_game_team', with: 'Team'
      attach_file(
        'indie_space_game_thumbnail',
        Rails.root.join('spec/support/brands/logos/TGDF.png')
      )
      click_button '新增Game'
    end

    it { expect(page).to(have_content('Example')) }
  end

  describe '#edit' do
    it 'can edit game' do # rubocop:disable RSpec/ExampleLength
      visit edit_admin_indie_space_game_path(game)
      fill_in 'indie_space_game_name', with: 'New Game Name'
      attach_file(
        'indie_space_game_thumbnail',
        Rails.root.join('spec/support/brands/logos/TGDF.png')
      )
      click_button '更新Game'
      expect(page).to(have_content('New Game Name'))
    end
  end

  describe '#destroy' do
    let!(:game) { create(:game, type: 'IndieSpace::Game') }

    it 'can destroy game' do
      visit admin_indie_space_games_path

      within first('td', text: game.name).first(:xpath, './/..') do
        click_button 'Destroy'
      end

      expect(page).not_to(have_content(game.name))
    end
  end
end
