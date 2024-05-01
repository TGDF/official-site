# frozen_string_literal: true

Given('there are some agenda tags') do |table|
  table.hashes.each do |tag|
    AgendaTag.create!(tag)
  end
end

Given('there are some agenda rooms') do |table|
  table.hashes.each do |room|
    Room.create!(room)
  end
end
