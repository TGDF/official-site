# frozen_string_literal: true

CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = false if Rails.env.test?
end
