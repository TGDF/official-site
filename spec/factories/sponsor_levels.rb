# frozen_string_literal: true

FactoryBot.define do
  factory :sponsor_level do
    name { Faker::Name.name }
  end
end
