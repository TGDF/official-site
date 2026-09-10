# frozen_string_literal: true

# SimpleCov starts before cucumber/rails loads the app; eager loading under CI
# would otherwise load every file untracked.
require 'simplecov'

# CI judges each suite on its own run, as GitHub runs them in separate jobs.
if ENV['CI']
  SimpleCov.merging false
  SimpleCov.minimum_coverage 77
end
SimpleCov.start('rails')

require 'cucumber/rails'

ActionController::Base.allow_rescue = false
Cucumber::Rails::Database.javascript_strategy = :truncation
