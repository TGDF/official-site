# frozen_string_literal: true

class Block < ApplicationRecord
  include HasTranslation

  acts_as_tenant :site, optional: true, has_global_records: true

  enum :language, {
    'zh-TW': 'zh-TW',
    en: 'en'
  }

  enum :page, {
    night_market: 'night_market'
  }

  enum :component_type, {
    text: 'text',
    twitch_live: 'twitch_live'
  }

  scope :ordered, -> { order(order: :asc) }
end
