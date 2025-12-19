# frozen_string_literal: true

module ImageVariants
  AVATAR = {
    v1: { resize_to_fill: [ 270, 270 ] },
    v1_large: { resize_to_fill: [ 370, 370 ] }
  }.freeze

  GAME_THUMBNAIL = {
    thumb: { resize_to_fill: [ 640, 360 ] },
    large: { resize_to_fill: [ 1920, 1080 ] }
  }.freeze

  SLIDER = {
    large: { resize_to_fill: [ 1920, 850 ] },
    thumb: { resize_to_fill: [ 384, 170 ] }
  }.freeze

  NEWS_THUMBNAIL = {
    thumb: { resize_to_fill: [ 570, 355 ] },
    large: { resize_to_fill: [ 1920, 420 ] },
    medium: { resize_to_fill: [ 770, 420 ] },
    small_square: { resize_to_fill: [ 80, 80 ] }
  }.freeze

  LOGO = {
    v1: { resize_to_fill: [ 270, 120 ] }
  }.freeze

  SITE_LOGO = {
    default: { resize_to_fit: [ 400, 60 ] }
  }.freeze

  SITE_FIGURE = {
    default: { resize_to_fill: [ 1920, 1080 ] }
  }.freeze
end
