# frozen_string_literal: true

FactoryBot.define do
  factory :game do
    name { Faker::Name.name }
    description { Faker::Lorem.paragraph }
    team { Faker::Name.name }
    video {}
    thumbnail do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/support/brands/logos/TGDF.png'),
        'image/jpeg'
      )
    end
  end
end
