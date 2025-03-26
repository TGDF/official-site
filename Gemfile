# frozen_string_literal: true

source "https://rubygems.org"

ruby "~> 3.3.0"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 8.0.2"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", ">= 0.18", "< 2.0"
# Use Puma as the app server
gem "puma", "~> 6.6"
# Use SCSS for stylesheets
# gem 'sassc-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Config
gem "config"
gem "devise-i18n"
gem "rails-i18n"

# Multi-Tenancy
gem "acts_as_tenant"
gem "ros-apartment", require: "apartment"

# User
gem "devise"
# gem 'omniauth-facebook'

# Front End
gem "cssbundling-rails"
gem "friendly_id", "~> 5.5.1"
gem "jsbundling-rails"
gem "mobility", "~> 1.3"
gem "select2-rails"
gem "simple_form"
gem "slim-rails"
gem "turbo-rails"
gem "view_component"

# SEO
gem "meta-tags"
gem "sitemap_generator"

# Monitor
gem "sentry-rails"
gem "sentry-ruby"
gem "stackprof"

# Feature
gem "flipper-active_record"
gem "flipper-active_support_cache_store"
gem "flipper-ui"

# Architecture
gem "dry-monads"
gem "dry-rails"
gem "dry-transaction"

# Utilities
gem "activerecord-import"
gem "aws-sdk-s3", require: false
gem "carrierwave"
gem "fog-aws"
gem "gretel"
gem "irb"
gem "liveness"
gem "mini_magick"
gem "oj"
gem "openbox"
gem "rack-attack"
gem "rack-utf8_sanitizer"
gem "store_attribute", "~> 2.0"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]

  gem "dotenv-rails"

  gem "factory_bot_rails", "~> 6.4.4"
  gem "faker"
  gem "fuubar"
  gem "rspec-rails"
  gem "shoulda"
  gem "shoulda-matchers"
  gem "simplecov", require: false

  gem "capybara", require: false
  gem "capybara-selenium", require: false

  gem "brakeman", require: false
  gem "rubocop", "~> 1.74.0", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
end

group :development do
  gem "debug"

  gem "lookbook"
  gem "web-console", ">= 3.3.0"

  gem "overcommit", require: false

  gem "amazing_print"

  gem "boxing"
end

group :test do
  gem "cucumber-rails", require: false
  gem "database_rewinder"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
