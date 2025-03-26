# frozen_string_literal: true

namespace :upgrade do
  namespace :indie_space do
    task migrate_game_to_indie_space: :environment do
      Site.pluck(:tenant_name).each do |tenant|
        Apartment::Tenant.switch(tenant) do
          Game.update_all(type: "IndieSpace::Game") # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end
end
