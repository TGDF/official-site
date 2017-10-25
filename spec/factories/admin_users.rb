# frozen_string_literal: true

FactoryBot.define do
  factory :admin_user do
    email    { Faker::Internet.email }
    password { Devise.friendly_token }
  end
end
