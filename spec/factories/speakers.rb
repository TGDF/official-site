# frozen_string_literal: true

FactoryBot.define do
  factory :speaker do
    name { Faker::Name.name }
    description { Faker::Lorem.paragraph }
    avatar do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec', 'support', 'avatars', 'Aotoki.jpg'),
        'image/jpeg'
      )
    end
  end
end
