# frozen_string_literal: true

Before do |_scenario|
  begin
    Apartment::Tenant.drop('main')
  rescue StandardError
    nil
  end

  site = Site.create!(name: 'Main Site', domain: 'www.example.com', tenant_name: 'main')
  Apartment::Tenant.switch!('main')
  ActsAsTenant.current_tenant = site
end

# Ensure run after the main tenant is created
Before('@night_market_enabled') do |_scenario|
  site = Site.find_by(tenant_name: 'main')
  site.update(night_market_enabled: true)
end

Before('@streaming') do |_scenario|
  site = Site.find_by(tenant_name: 'main')
  site.update(streaming_enabled: true)
end

Before('@cfp_mode') do |_scenario|
  site = Site.find_by(tenant_name: 'main')
  site.update(cfp_only_mode: true)
end

After do
  Apartment::Tenant.reset
  ActsAsTenant.current_tenant = nil
  DatabaseRewinder.clean_all
end
