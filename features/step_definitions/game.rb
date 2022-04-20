# frozen_string_literal: true

Then('I can see the game in the page') do |table|
  table.hashes.each do |row|
    expect(page).not_to have_xpath("//div[contains(@class, 'indie-game__name') and contains(., '#{row[:text]}')]")
  end
end
