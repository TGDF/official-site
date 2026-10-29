# frozen_string_literal: true

Given('there are some night market games') do |table|
  table.hashes.each do |game|
    game[:thumbnail_attachment] = uploaded_thumbnail(game.delete('thumbnail'))
    NightMarket::Game.create!(**game)
  end
end
