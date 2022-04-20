# frozen_string_literal: true

Around('@night_market_enabled') do |_scenario, block|
  site = Site.find_by(tenant_name: 'main')
  site.update(night_market_enabled: true)
  block&.call
  site.update(night_market_enabled: false)
end
