# frozen_string_literal: true

# require 'apartment/elevators/generic'
require 'apartment/elevators/domain'
# require 'apartment/elevators/subdomain'
# require 'apartment/elevators/first_subdomain'

#
# Apartment Configuration
#
Apartment.configure do |config|
  config.excluded_models = %w[Site AdminUser]

  config.tenant_names = -> { Site.pluck(:tenant_name) }
  config.use_sql = true

  # config.persistent_schemas = %w{ hstore }
end

# Rails.application.config.middleware.use Apartment::Elevators::Domain
# Rails.application.config.middleware.use Apartment::Elevators::Subdomain
# Rails.application.config.middleware.use Apartment::Elevators::FirstSubdomain
Rails.application.config.middleware.use FullHostElevators
