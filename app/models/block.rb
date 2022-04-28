# frozen_string_literal: true

class Block < ApplicationRecord
  include HasTranslation

  enum language: {
    'zh-TW': 'zh-TW',
    en: 'en'
  }

  enum page: {
    night_market: 'night_market'
  }

  scope :ordered, -> { order(order: :asc) }
end
