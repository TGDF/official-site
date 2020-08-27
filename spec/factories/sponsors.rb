# frozen_string_literal: true

FactoryBot.define do
  factory :sponsor do
    name { Faker::Name.name }
    logo do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/support/brands/logos/TGDF.png'),
        'image/jpeg'
      )
    end
    level { create(:sponsor_level) }
  end
end
