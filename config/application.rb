# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tgdf
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.i18n.default_locale = :'zh-TW'
    config.i18n.fallbacks = true
    config.i18n.available_locales = %i[
      zh-TW
      en
    ]

    # Don't generate system test files.
    config.generators do |g|
      g.system_tests = nil
      g.test_framework :rspec
      g.stylesheets false
      g.javascripts false
      g.helper false
      g.template_engine :erb
    end

    config.middleware.insert(0, Rack::UTF8Sanitizer)
  end
end
