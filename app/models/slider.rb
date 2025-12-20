# frozen_string_literal: true

class Slider < ApplicationRecord
  include HasTranslation
  include HasMigratedUpload

  acts_as_tenant :site, optional: true
  mount_uploader :image, SliderUploader
  has_migrated_upload :image, variants: ImageVariants::SLIDER

  enum :language, {
    'zh-TW': 0,
    en: 1
  }

  enum :page, {
    home: 0,
    indie_spaces: 1,
    night_market: 2
  }

  validates :language, presence: true
  validate { errors.add(:image, :blank) unless image_present? }
end
