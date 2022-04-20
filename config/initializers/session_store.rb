# frozen_string_literal: true

unless Rails.env.test?
  Rails.application.config.session_store(
    :cookie_store,
    key: Settings.site.session_key,
    domain: %W[.#{Settings.site.default_domain} #{Settings.site.default_domain}],
    secure: Rails.env.production?
  )
end
