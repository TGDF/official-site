# frozen_string_literal: true

Given('there are some slide in {string}') do |page_name, table|
  table.hashes.each do |slider|
    slider[:image] = uploaded_thumbnail(slider[:image])
    slider[:page] = page_name
    Slider.create!(**slider)
  end
end

Then('I can see the {int} slide in page') do |amount|
  expect(page).to have_css('#slider .swiper-slide', count: amount)
end
