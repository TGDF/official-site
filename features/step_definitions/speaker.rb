# frozen_string_literal: true

Given('there are some speakers') do |table|
  table.hashes.each do |speaker|
    speaker[:avatar] = uploaded_thumbnail(speaker[:avatar])
    Speaker.create!(**speaker)
  end
end
