# frozen_string_literal: true

require 'cucumber/rails'

ActionController::Base.allow_rescue = false
Cucumber::Rails::Database.javascript_strategy = :truncation
