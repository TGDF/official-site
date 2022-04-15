# frozen_string_literal: true

BeforeAll do
  begin
    Apartment::Tenant.drop('main')
  rescue # rubocop:disable Style/RescueStandardError
    nil
  end

  Site.create!(name: 'Main Site', domain: 'www.example.com', tenant_name: 'main')
end

Around do |_scenario, block|
  Apartment::Tenant.switch('main', &block)
end
