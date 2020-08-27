# frozen_string_literal: true

class AddTenantNameToSites < ActiveRecord::Migration[5.1]
  def change
    add_column(:sites, :tenant_name, :string)
    add_index(:sites, :tenant_name)

    reversible do |direction|
      direction.up { apply_tenant_name if main_site? }
      direction.down { alert_with_rollback if main_site? }
    end
  end

  def apply_tenant_name
    say_with_time 'Create default tenant name for exists site' do
      Site.in_batches do |group|
        group.each { |site| site.update(tenant_name: site.domain.tr('.', '_')) }
      end
      Site.count
    end
  end

  def alert_with_rollback
    say_with_time 'Rollback will cause tenant broken, press Ctrl-C in 10 seconds to stop it' do
      sleep 10
      Site.count
    end
  end

  def main_site?
    Apartment::Tenant.current == 'public'
  end
end
