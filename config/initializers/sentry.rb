# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.profiles_sample_rate = 1.0
  config.traces_sampler = lambda do |sampling_context|
    next sampling_context[:parent_sampled] unless sampling_context[:parent_sampled].nil?

    transaction_context = sampling_context[:transaction_context]
    next true unless transaction_context[:op].include?('http')
    next false if transaction_context[:name].include?('/status')

    1.0
  end
end
