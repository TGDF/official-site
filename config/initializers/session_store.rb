# frozen_string_literal: true

unless Rails.env.test?
  Rails.application.config.session_store(
    :cookie_store,
    key: "_tgdf_session_#{Rails.env}",
    domain: %W[.#{Settings.site.default_domain} #{Settings.site.default_domain}],
    secure: Rails.env.production?
  )
end
