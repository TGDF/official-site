# frozen_string_literal: true

FactoryBot.define do
  factory :agenda_time do
    sequence(:label) { |i| "Time #{i}" }
    order 1
  end
end
