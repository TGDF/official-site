# frozen_string_literal: true

CarrierWave.configure do |config|
  if Settings.s3.enabled
    config.storage = :fog
    config.fog_credentials = {
      provider: 'AWS',
      aws_access_key_id: Settings.s3.access_key_id,
      aws_secret_access_key: Settings.s3.secret_access_key,
      region: Settings.s3.region,
      path_style: true
    }
    config.fog_directory  = Settings.s3.bucket
    config.fog_public     = true
    config.fog_attributes = { cache_control: "public, max-age=#{365.days.to_i}" }
  else
    config.storage = :file
  end

  config.enable_processing = false if Rails.env.test?
  config.asset_host = Settings.assets.host
end
