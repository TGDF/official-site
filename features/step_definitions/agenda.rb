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

Given('there are some agenda days') do |table|
  table.hashes.each do |day|
    AgendaDay.create!(day)
  end
end

Given('there are some agenda times') do |table|
  table.hashes.each do |time|
    time['day'] = AgendaDay.find_by(label: time.delete('day'))
    AgendaTime.create!(time)
  end
end

Given('there are some agenda') do |table|
  table.hashes.each do |agenda|
    Agenda.create!(agenda)
  end
end
