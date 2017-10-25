# frozen_string_literal: true

FactoryBot.define do
  factory :news do
    title { Faker::Lorem.sentence }
    slug { Faker::Lorem.word }
    content { Faker::Lorem.paragraph }
    author { create(:admin_user) }
  end
end
