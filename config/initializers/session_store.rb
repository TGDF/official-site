# frozen_string_literal: true

Rails.application.config.session_store :cookie_store, key: "_tgdf_session_#{Rails.env}", domain: ".#{Settings.site.default_domain}" unless Rails.env.test?
