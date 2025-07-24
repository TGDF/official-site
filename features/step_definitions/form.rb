# frozen_string_literal: true

When('I select options in the {string} form') do |form, table|
  table.rows.each do |key, option|
    field_name = "#{form}_#{key}"

    # Check if this is a legacy date field (date_1i, date_2i, date_3i)
    if key.match(/^date_[123]i$/)
      # Try to find the select box, if not found, skip (V2 uses date_field instead)
      if has_select?(field_name)
        select option, from: field_name
      else
        # This is V2 - we should have updated the scenario to use date field
        # Skip this step as the date should be handled by fill_in step
        next
      end
    else
      select option, from: field_name
    end
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
