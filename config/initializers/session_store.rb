# frozen_string_literal: true

Rails.application.config.session_store :cookie_store, key: '_tgdf_session', domain: Settings.site.default_domain, tld_length: 1
