# frozen_string_literal: true

CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = false if Rails.env.test?
  config.asset_host = Settings.assets.host
end
