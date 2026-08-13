# frozen_string_literal: true

FactoryBot.define do
  factory :agendas_tagging do
    agenda
    tag { association :agenda_tag }
  end
end
