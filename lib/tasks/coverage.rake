namespace :coverage do
  task :report do
    require 'simplecov'

    SimpleCov.collate Dir['simplecov-resultset-*/.resultset.json']
  end
end
