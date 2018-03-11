# frozen_string_literal: true

Rollbar.configure do |config|
  config.access_token = ENV['ROLLBAR_ACCESS_TOKEN']
  config.enabled = false unless Rails.env.production?
  config.environment = ENV['ROLLBAR_ENV'].presence || Rails.env
end
