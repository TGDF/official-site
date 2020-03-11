# frozen_string_literal: true

Rack::Attack.throttle('admin/sign_in', limit: 20, period: 1.hour) do |req|
  req.ip if req.path == '/admin/sign_in' && req.post?
end

ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _request_id, req|
  Rails.logger.tagged('Rack::Attack') do
    Rails.logger.warn "Throttled #{req.env['rack.attack.match_discriminator']}"
  end
end
