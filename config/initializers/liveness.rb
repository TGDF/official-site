# frozen_string_literal: true

Liveness.config do |c|
  c.add :postgres, timeout: 10
end
