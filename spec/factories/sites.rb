# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    name { Faker::Name.name }
    sequence(:domain) { |id| "#{id}.#{Faker::Internet.domain_name}" }
    sequence(:tenant_name) { |id| "tgdf_#{id}" }
  end
end
