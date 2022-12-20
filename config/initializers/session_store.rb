# frozen_string_literal: true

require_dependency 'settings'

unless Rails.env.test?
  Rails.application.config.session_store(
    :cookie_store,
    key: Settings.site.session_key,
    domain: Rails.env.production? ? %W[.#{Settings.site.default_domain} #{Settings.site.default_domain}] : nil,
    secure: Rails.env.production?
  )
end
