# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # Truncating doesn't drop schemas, ensure we're clean here, app *may not* exist
    begin
      Apartment::Tenant.drop('main')
    rescue # rubocop:disable Style/RescueStandardError
      nil
    end
    # Create the default tenant for our tests
    Site.create!(name: 'Main Site', domain: 'www.example.com', tenant_name: 'main')
  end

  config.before(:each) do
    # Switch into the default tenant
    Apartment::Tenant.switch! 'main'
  end

  config.after(:each) do
    # Reset tentant back to `public`
    Apartment::Tenant.reset
  end
end
