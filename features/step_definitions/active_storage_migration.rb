# frozen_string_literal: true

# =============================================================================
# Feature Flag Steps
# =============================================================================

Given('ActiveStorage read is disabled') do
  Flipper.disable(:active_storage_read)
end

Given('ActiveStorage read is enabled') do
  Flipper.enable(:active_storage_read)
end

Given('ActiveStorage write is disabled') do
  Flipper.disable(:active_storage_write)
end

Given('ActiveStorage write is enabled') do
  Flipper.enable(:active_storage_write)
end

# =============================================================================
# Speaker Steps
# =============================================================================

Given('speaker {string} has ActiveStorage attachment') do |name|
  speaker = Speaker.i18n.find_by!(name: name)
  speaker.avatar_attachment.attach(
    io: File.open(Rails.root.join('spec/support/brands/logos/TGDF.png')),
    filename: 'avatar.png',
    content_type: 'image/png'
  )
end

Given('speaker {string} does not have ActiveStorage attachment') do |name|
  speaker = Speaker.i18n.find_by!(name: name)
  speaker.avatar_attachment.purge if speaker.avatar_attachment.attached?
end

Then('I can see speaker {string} with CarrierWave avatar') do |_name|
  expect(page).to have_css("img[src*='uploads/']")
end

Then('I can see speaker {string} with ActiveStorage avatar') do |_name|
  expect(page).to have_css("img[src*='rails/active_storage'], img[src*='/blobs/']")
end

Then('speaker {string} should have ActiveStorage attachment') do |name|
  speaker = Speaker.i18n.find_by!(name: name)
  expect(speaker.avatar_attachment).to be_attached
end

# =============================================================================
# Site Steps
# =============================================================================

Given('there is a site without logo') do
  site = Site.first || create(:site)
  site.update!(logo: nil)
  site.logo_attachment.purge if site.logo_attachment.attached?
end

Given('there is a site with ActiveStorage logo') do
  site = Site.first || create(:site)
  site.logo_attachment.attach(
    io: File.open(Rails.root.join('spec/support/brands/logos/TGDF.png')),
    filename: 'logo.png',
    content_type: 'image/png'
  )
end

Given('site has ActiveStorage figure') do
  site = Site.first || create(:site)
  site.figure_attachment.attach(
    io: File.open(Rails.root.join('spec/support/brands/logos/TGDF.png')),
    filename: 'figure.png',
    content_type: 'image/png'
  )
end

Then('I can see the default site logo') do
  expect(page).to have_css("img[src*='logo']")
end

Then('I can see the ActiveStorage site logo') do
  site = Site.first
  expect(site.logo_attachment).to be_attached
  expect(page).to have_css("img[src*='rails/active_storage']")
end

# =============================================================================
# News Steps
# =============================================================================

Given('news {string} has ActiveStorage attachment') do |title|
  news = News.i18n.find_by!(title: title)
  news.thumbnail_attachment.attach(
    io: File.open(Rails.root.join('spec/support/brands/logos/TGDF.png')),
    filename: 'thumbnail.png',
    content_type: 'image/png'
  )
end

Then('I can see news with CarrierWave thumbnail') do
  # News uses NewsListItemComponent which wraps NewsThumbnailComponent
  expect(page).to have_css("#news article img[src*='uploads/']")
end

Then('I can see news with ActiveStorage thumbnail') do
  expect(page).to have_css("#news article img[src*='rails/active_storage'], #news article img[src*='/blobs/']")
end

# =============================================================================
# Sponsor Steps
# =============================================================================

Given('sponsor {string} has ActiveStorage attachment') do |name|
  sponsor = Sponsor.i18n.find_by!(name: name)
  sponsor.logo_attachment.attach(
    io: File.open(Rails.root.join('spec/support/brands/logos/TGDF.png')),
    filename: 'logo.png',
    content_type: 'image/png'
  )
end

Then('I can see sponsor with CarrierWave logo') do
  # Sponsors use PartnerLogoComponent in #ticket section
  expect(page).to have_css("#ticket img[src*='uploads/']")
end

Then('I can see sponsor with ActiveStorage logo') do
  expect(page).to have_css("#ticket img[src*='rails/active_storage'], #ticket img[src*='/blobs/']")
end

# =============================================================================
# Partner Steps
# =============================================================================

Given('partner {string} has ActiveStorage attachment') do |name|
  partner = Partner.i18n.find_by!(name: name)
  partner.logo_attachment.attach(
    io: File.open(Rails.root.join('spec/support/brands/logos/TGDF.png')),
    filename: 'logo.png',
    content_type: 'image/png'
  )
end

Then('I can see partner with CarrierWave logo') do
  # Partners use PartnerLogoComponent in #ticket section
  expect(page).to have_css("#ticket img[src*='uploads/']")
end

Then('I can see partner with ActiveStorage logo') do
  expect(page).to have_css("#ticket img[src*='rails/active_storage'], #ticket img[src*='/blobs/']")
end

# =============================================================================
# Slider Steps
# =============================================================================

Given('the slider has ActiveStorage attachment') do
  slider = Slider.first!
  slider.image_attachment.attach(
    io: File.open(Rails.root.join('spec/support/brands/logos/TGDF.png')),
    filename: 'slider.png',
    content_type: 'image/png'
  )
end

Then('I can see slider with CarrierWave image') do
  # Sliders use swiper-slide class
  expect(page).to have_css(".swiper-slide img[src*='uploads/']")
end

Then('I can see slider with ActiveStorage image') do
  expect(page).to have_css(".swiper-slide img[src*='rails/active_storage'], .swiper-slide img[src*='/blobs/']")
end

# =============================================================================
# Game Steps
# =============================================================================

Given('game {string} has ActiveStorage attachment') do |name|
  game = Game.i18n.find_by!(name: name)
  game.thumbnail_attachment.attach(
    io: File.open(Rails.root.join('spec/support/brands/logos/TGDF.png')),
    filename: 'thumbnail.png',
    content_type: 'image/png'
  )
end

Then('I can see game with CarrierWave thumbnail') do
  # Games use .indie-game__picture for the thumbnail container
  expect(page).to have_css(".indie-game__picture img[src*='uploads/']")
end

Then('I can see game with ActiveStorage thumbnail') do
  expect(page).to have_css(".indie-game__picture img[src*='rails/active_storage'], .indie-game__picture img[src*='/blobs/']")
end

# =============================================================================
# ActiveStorage Write Steps
# =============================================================================

When('I attach files to ActiveStorage in the {string} form') do |form, table|
  table.rows.each do |key, value|
    attach_file(
      "#{form}_#{key}_attachment",
      Rails.root.join("spec/support/brands/logos/#{value}")
    )
  end
end
