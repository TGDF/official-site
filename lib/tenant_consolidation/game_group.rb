# frozen_string_literal: true

module TenantConsolidation
  # The game group. Every game moves as it is: `type` carries over, so the Indie
  # Space and Night Market games stay apart, and a locale a game never had stays
  # missing for Mobility's fallback to cover.
  module GameGroup
    NAME = "game"
    MODELS = %w[Game].freeze
    UPLOADS = { "Game" => :thumbnail }.freeze
    TARGETS = %w[Game].freeze

    module_function

    def plan(site)
      Plan.carry(site, MODELS)
    end
  end
end
