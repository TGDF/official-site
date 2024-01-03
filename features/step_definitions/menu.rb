# frozen_string_literal: true

Given('there have a {string} menu with') do |menu_id, table|
  table.hashes.each do |row|
    MenuItem.create!(
      name: row['name'],
      link: row['link'],
      visible: row['visible'] == 'yes',
      menu_id:
    )
  end
end
