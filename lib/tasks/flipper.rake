# frozen_string_literal: true

namespace :flipper do
  desc "Setup admin_v1_legacy feature flag"
  task setup_admin_v1_legacy: :environment do
    # Ensure the feature exists in Flipper
    if Flipper.exist?(:admin_v1_legacy)
      puts "Feature flag 'admin_v1_legacy' already exists"
    else
      # Add the feature to Flipper (it will be disabled by default)
      Flipper.add(:admin_v1_legacy)
      puts "Feature flag 'admin_v1_legacy' has been created (disabled by default)"
    end

    # Show current status
    puts "Current status: #{Flipper.enabled?(:admin_v1_legacy) ? 'enabled' : 'disabled'}"
  end
end
