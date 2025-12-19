# frozen_string_literal: true

Before do
  Flipper.instance = Flipper.new(Flipper::Adapters::Memory.new)
end

Before('@preview') do
  Flipper.enable(:preview)
end

Before('@active_storage_read') do
  Flipper.enable(:active_storage_read)
end

Before('@active_storage_write') do
  Flipper.enable(:active_storage_write)
end
