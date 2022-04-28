# frozen_string_literal: true

When('I select options in the {string} form') do |form, table|
  table.rows.each do |key, option|
    select option, from: "#{form}_#{key}"
  end
end

When('I fill the {string} form') do |form, table|
  table.rows.each do |key, value|
    fill_in "#{form}_#{key}", with: value
  end
end

When('I attach files in the {string} form') do |form, table|
  table.rows.each do |key, value|
    attach_file(
      "#{form}_#{key}",
      Rails.root.join("spec/support/brands/logos/#{value}")
    )
  end
end
