# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # Truncating doesn't drop schemas, ensure we're clean here, app *may not* exist
    begin
      Apartment::Tenant.drop('main')
    rescue # rubocop:disable Style/RescueStandardError
      nil
    end

    DatabaseRewinder.clean_all
    # Create the default tenant for our tests
    Site.create!(name: 'Main Site', domain: 'www.example.com', tenant_name: 'main')
  end

  config.before do
    # Switch into the default tenant
    Apartment::Tenant.switch! 'main'
  end

  config.after do
    DatabaseRewinder.clean
    # Reset tentant back to `public`
    Apartment::Tenant.reset
  end
end
