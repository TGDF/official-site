# frozen_string_literal: true

Given('there are some night market games') do |table|
  table.hashes.each do |game|
    game[:thumbnail] = uploaded_thumbnail(game[:thumbnail])
    NightMarket::Game.create!(**game)
  end
end

Then('I should see night market games are listed') do |table|
  table.hashes.each do |game|
    expect(page).to have_text(game[:name])
  end
end
