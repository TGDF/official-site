# frozen_string_literal: true

Given('there are some indie space games') do |table|
  table.hashes.each do |game|
    game[:thumbnail] = uploaded_thumbnail(game[:thumbnail])
    IndieSpace::Game.create!(**game)
  end
end
