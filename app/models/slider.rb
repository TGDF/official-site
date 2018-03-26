# frozen_string_literal: true

class Slider < ApplicationRecord
  mount_uploader :image, SliderUploader

  validates :image, presence: true
end
