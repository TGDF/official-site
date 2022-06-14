# frozen_string_literal: true

FactoryBot.define do
  factory :block do
    content { 'MyText' }
    language { 'zh-TW' }
    page { 'night_market' }
    component_type { 'text' }
  end

  factory :text_block, parent: :block
  factory :twitch_live_block, parent: :block do
    component_type { 'twitch_live' }
  end
end
