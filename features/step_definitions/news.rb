# frozen_string_literal: true

Given('there are some news') do |table|
  author = create(:admin_user)

  table.hashes.each do |attributes|
    News.create!(**attributes, author:, thumbnail: uploaded_thumbnail)
  end
end

Then('I can see some news') do |table|
  table.hashes.each do |news|
    expect(page).to have_content(news[:title])
  end
end
