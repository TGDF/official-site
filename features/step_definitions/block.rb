# frozen_string_literal: true

Given('there are some block in {string}') do |page_name, table|
  table.hashes.each do |block|
    block[:page] = page_name
    Block.create!(**block)
  end
end

Then('I can see the text block with {string}') do |string|
  expect(page).to have_css('.text-block', text: string)
end

Then('I can see twitch embed placeholder') do
  expect(page).to have_css('#twitch-embed')
end
