# frozen_string_literal: true

source 'https://rubygems.org'

ruby '~> 2.7.0'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.5'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 6.0'
# Use SCSS for stylesheets
# gem 'sassc-rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Config
gem 'rails-i18n'
gem 'settingslogic'

# Multi-Tenancy
gem 'ros-apartment', require: 'apartment'

# User
gem 'devise'
# gem 'omniauth-facebook'

# Front End
gem 'cssbundling-rails'
gem 'friendly_id', '~> 5.4.0'
gem 'jsbundling-rails'
gem 'mobility', '~> 1.0'
gem 'select2-rails'
gem 'simple_form'
gem 'slim-rails'
gem 'turbo-rails'
gem 'view_component'

# SEO
gem 'meta-tags'
gem 'sitemap_generator'

# Monitor
gem 'sentry-rails'
gem 'sentry-ruby'

# Utilities
gem 'carrierwave'
gem 'fog-aws'
gem 'gretel'
gem 'liveness'
gem 'mini_magick'
gem 'oj'
gem 'openbox'
gem 'rack-attack'
gem 'rack-utf8_sanitizer'
gem 'store_attribute', '~> 1.0'
gem 'whenever', require: false

# API
gem 'grape'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]

  gem 'dotenv-rails'

  gem 'factory_bot_rails'
  gem 'faker'
  gem 'fuubar'
  gem 'rspec-rails'
  gem 'shoulda'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false

  gem 'bcrypt_pbkdf'
  gem 'capybara', require: false
  gem 'capybara-selenium', require: false

  gem 'brakeman', require: false
  gem 'rubocop', '~> 1.8.1', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'

  gem 'overcommit', require: false

  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'pry-rails'

  gem 'boxing'
end

group :test do
  gem 'cucumber-rails', require: false
  gem 'database_rewinder'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
