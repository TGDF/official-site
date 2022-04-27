# frozen_string_literal: true

class Slider < ApplicationRecord
  mount_uploader :image, SliderUploader

  enum language: {
    'zh-TW': 0,
    en: 1
  }

  enum page: {
    home: 0,
    indie_spaces: 1,
    night_market: 2
  }

  validates :image, :language, presence: true

  scope :localized, -> { where(language: I18n.locale) }
end
