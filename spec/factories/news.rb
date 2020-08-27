# frozen_string_literal: true

FactoryBot.define do
  factory :news do
    title { Faker::Lorem.sentence }
    sequence(:slug) { |id| "#{Faker::Lorem.word}_#{id}" }
    content { Faker::Lorem.paragraph }
    author { create(:admin_user) }
    thumbnail do
      Rack::Test::UploadedFile.new(
        Rails.root.join('spec/support/brands/logos/TGDF.png'),
        'image/jpeg'
      )
    end
  end
end
