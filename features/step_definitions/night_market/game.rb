# frozen_string_literal: true

Given('there are some night market games') do |table|
  table.hashes.each do |game|
    game[:thumbnail] = uploaded_thumbnail(game[:thumbnail])
    NightMarket::Game.create!(**game)
  end
end

When('I fill the Night Market Game form') do |table|
  table.rows.each do |key, value|
    if key == 'thumbnail'
      attach_file(
        'night_market_game_thumbnail',
        Rails.root.join("spec/support/brands/logos/#{value}")
      )
      next
    end
    fill_in "night_market_game_#{key}", with: value
  end
end
