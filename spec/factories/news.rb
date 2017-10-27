# frozen_string_literal: true

FactoryBot.define do
  factory :news do
    title { Faker::Lorem.sentence }
    sequence(:slug) { |id| "#{Faker::Lorem.word}_#{id}" }
    content { Faker::Lorem.paragraph }
    author { create(:admin_user) }
  end
end
