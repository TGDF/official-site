# frozen_string_literal: true

FactoryBot.define do
  factory :agendas_speaker do
    association :agenda
    association :speaker
  end
end
