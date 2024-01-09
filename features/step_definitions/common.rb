# frozen_string_literal: true

When('I visit {string}') do |path|
  visit path
end

When('I click {string}') do |name|
  click_on name
end

When('I click {string} button') do |button_name|
  click_on button_name
end

When('I click {string} on row {string}') do |clickable_name, text_in_row|
  within :xpath, "//tr[td='#{text_in_row}']" do
    click_on clickable_name
  end
end

When('I click link {string}') do |link_name|
  click_on link_name
end

When('I click {string} in menu') do |menu_item|
  within :xpath, "//nav[contains(@id, 'main-menu')]" do
    click_on menu_item
  end
end

When('I click admin sidebar {string} in {string}') do |menu_item, menu_group|
  within :xpath, "//aside[contains(@class, 'c-sidebar')]/ul/li[contains(., '#{menu_group}')]" do
    click_on menu_item
  end
end

Then('I can see {string}') do |text|
  expect(page).to have_text(text)
end

Then('I can see {string} in menu') do |text|
  within :xpath, "//nav[contains(@id, 'main-menu')]" do
    expect(page).to have_text(text)
  end
end

Then('I can not see {string} in menu') do |text|
  within :xpath, "//nav[contains(@id, 'main-menu')]" do
    expect(page).to have_no_text(text)
  end
end

Then('I can see these items in table') do |table|
  table.hashes.each do |row|
    expect(page).to have_css('tr td', text: row[:text])
  end
end

Then('I should not see in the table') do |table|
  table.hashes.each do |row|
    expect(page).to have_no_css('tr td', text: row[:text])
  end
end
