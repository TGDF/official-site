# frozen_string_literal: true

FactoryBot.define do
  factory :agendas_tagging do
    association :agenda
    association :agenda_tag
  end
end
