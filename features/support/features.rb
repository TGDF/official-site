# frozen_string_literal: true

Around('@night_market_enabled') do |_scenario, block|
  site = Site.find_by(tenant_name: 'main')
  site.update(night_market_enabled: true)
  block&.call
  site.update(night_market_enabled: false)
end

Around('@streaming') do |_scenario, block|
  site = Site.find_by(tenant_name: 'main')
  site.update(streaming_enabled: true)
  block&.call
  site.update(streaming_enabled: false)
end

Before do
  Flipper.instance = Flipper.new(Flipper::Adapters::Memory.new)
end

Before('@preview') do
  Flipper.enable(:preview)
end
