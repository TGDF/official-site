# frozen_string_literal: true

FactoryBot.define do
  factory :agenda_day do
    sequence(:label) { |i| "Day #{i}" }
    date { Time.zone.now }
  end
end
