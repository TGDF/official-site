# frozen_string_literal: true

Then('I can see the game in the page') do |table|
  table.hashes.each do |row|
    expect(page).to have_xpath("//h3[contains(@class, 'indie-game__name') and contains(., '#{row[:text]}')]")
  end
end

Then('I can see the game video in the page') do |table|
  table.hashes.each do |row|
    expect(page).to have_xpath("//div[contains(@class, 'indie-game__video')]/a[contains(@href, '#{row[:video]}')]")
  end
end

Then('I can see the game developer in the page') do |table|
  table.hashes.each do |row|
    if row[:link].blank?
      expect(page).to have_xpath("//div[contains(@class, 'indie-game__team') and contains(., '#{row[:name]}')]")
    else
      expect(page)
        .to have_xpath("//div[contains(@class, 'indie-game__team')]/" \
                       "a[contains(@href, '#{row[:link]}') and contains(., '#{row[:name]}')]")
    end
  end
end
