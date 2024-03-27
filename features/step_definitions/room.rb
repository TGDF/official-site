# frozen_string_literal: true

Given('there are some rooms') do |table|
  table.hashes.each do |room|
    Room.create!(room)
  end
end
