# frozen_string_literal: true

# :nodoc:
module Rack
  class Attack
    throttle('admin/sign_in', limit: 5, period: 1.minute) do |req|
      req.ip if req.path == '/admin/sign_in' && req.post?
    end
  end
end
