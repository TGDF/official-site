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
  # Try to find row with exact text match first (V1 style)
  if has_xpath?("//tr[td='#{text_in_row}']")
    within :xpath, "//tr[td='#{text_in_row}']" do
      click_on clickable_name
    end
  else
    # Try to find row containing the text (V2 style with links)
    within :xpath, "//tr[td[contains(., '#{text_in_row}')]]" do
      click_on clickable_name
    end
  end
end

When('I click link {string}') do |link_name|
  click_on link_name
end

When('I click first {string} link') do |link_text|
  first(:link, link_text).click
end

When('I click {string} in menu') do |menu_item|
  within :xpath, "//nav[contains(@id, 'main-menu')]" do
    click_on menu_item
  end
end

When('I click admin sidebar {string} in {string}') do |menu_item, menu_group|
  # Try V2 structure first (default)
  if has_css?('nav[aria-label="Sidebar"]')
    within 'nav[aria-label="Sidebar"]' do
      # Find the group button and get its submenu ID
      group_button = find('button', text: menu_group)
      submenu_id = group_button['aria-controls']

      # Click the group button to expand if not already expanded
      unless group_button['aria-expanded'] == 'true'
        group_button.click
      end

      # Wait for submenu to be visible and click the menu item within it
      within "##{submenu_id}" do
        click_on menu_item
      end
    end
  else
    # Fallback to V1 structure for legacy support
    within :xpath, "//aside[contains(@class, 'c-sidebar')]/ul/li[contains(., '#{menu_group}')]" do
      click_on menu_item
    end
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
