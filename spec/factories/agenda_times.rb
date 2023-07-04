# frozen_string_literal: true

FactoryBot.define do
  factory :agenda_time do
    sequence(:label) { |i| "Time #{i}" }
    day { association :agenda_day }
    order { 1 }
  end
end
