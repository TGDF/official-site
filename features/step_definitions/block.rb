# frozen_string_literal: true

Given('there are some block in {string}') do |_page, _table|
  # pending
end

Then('I can see the text block with {string}') do |string|
  expect(page).to have_selector('.text-block', text: string)
end
