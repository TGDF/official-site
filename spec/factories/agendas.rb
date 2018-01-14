# frozen_string_literal: true

FactoryBot.define do
  factory :agenda do
    subject { Faker::Name.name }
    description { Faker::Lorem.paragraph }
  end
end
