# frozen_string_literal: true

When('I visit {string}') do |path|
  visit path
end

When('I click {string} button') do |button_name|
  click_button button_name
end
