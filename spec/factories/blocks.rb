# frozen_string_literal: true

FactoryBot.define do
  factory :block do
    content { 'MyText' }
    language { 'zh-TW' }
    page { 'night_market' }
    component_type { 'text' }
  end
end
