# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.traces_sampler = lambda do |sampling_context|
    transaction_context = sampling_context[:transaction_context]
    op = transaction_context[:op]
    transaction_name = transaction_context[:name]

    case op
    when /request/
      case transaction_name
      when /Controller\#/
        1.0
      else
        0.0
      end
    else
      1.0
    end
  end
end
