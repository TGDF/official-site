# frozen_string_literal: true

require "raix"
require "dotenv"

Dotenv.load

faraday_retry = false
begin
  require "faraday/retry"
  faraday_retry = true
rescue LoadError
  # Do nothing
end

Raix.configure do |config|
  config.openai_client = OpenAI::Client.new(
    access_token: ENV.fetch("OPENAI_API_KEY"),
    uri_base: "https://api.openai.com/v1",
  ) do |f|
    if faraday_retry
      f.request(:retry, {
        max: 2,
        interval: 0.05,
        interval_randomness: 0.5,
        backoff_factor: 2
      })
    end
  end
end
