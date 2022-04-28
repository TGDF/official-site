# frozen_string_literal: true

Given('there are some block in {string}') do |page_name, table|
  table.hashes.each do |block|
    block[:page] = page_name
    Block.create!(**block)
  end
end

Then('I can see the text block with {string}') do |string|
  expect(page).to have_selector('.text-block', text: string)
end

When('I fill the Block form') do |table|
  table.rows.each do |key, value|
    fill_in "block_#{key}", with: value
  end
end
