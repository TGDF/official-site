# frozen_string_literal: true

When('I visit {string}') do |path|
  visit path
end

When('I click {string} button') do |button_name|
  click_button button_name
end

When('I click {string} on row {string}') do |clickable_name, text_in_row|
  within :xpath, "//tr[td='#{text_in_row}']" do
    click_on clickable_name
  end
end

When('I click link {string}') do |link_name|
  click_on link_name
end
