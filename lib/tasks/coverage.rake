# frozen_string_literal: true

namespace :coverage do
  task report: :environment do
    require 'simplecov'

    SimpleCov.collate Dir['simplecov-resultset-*/.resultset.json'], 'rails'
  end
end
