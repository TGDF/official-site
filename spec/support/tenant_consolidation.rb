# frozen_string_literal: true

# Real tenant schemas for consolidation specs. Consolidation issues DDL (CREATE/DROP
# SCHEMA via Apartment) and switches schemas, neither of which fits inside the
# per-example fixture transaction, so a spec including this context runs without it
# and resets the public schema, the main tenant, and the extra tenants itself.
RSpec.shared_context 'with consolidation tenants' do
  self.use_transactional_tests = false

  let(:test_png) { Rails.root.join('spec/support/brands/logos/TGDF.png') }
  let(:main_site) { Site.find_by(tenant_name: 'main') }

  before { reset_consolidation_state! }
  after { reset_consolidation_state! }

  def extra_tenants
    %w[spec_cons_b spec_cons_asset]
  end

  def seeded_models
    [ Sponsor, SponsorLevel, Partner, PartnerType, Attachment, News ]
  end

  # A dangling Site whose schema is dropped would break the next example's
  # Site.find_each, so both are cleared together.
  def reset_consolidation_state!
    in_public do
      seeded_models.each { |model| model.unscoped.delete_all }
      Site.where(tenant_name: extra_tenants).delete_all
    end
    within_tenant(main_site) { seeded_models.each { |model| model.unscoped.delete_all } }
    extra_tenants.each { |name| drop_tenant(name) }
  end

  def drop_tenant(name)
    Apartment::Tenant.drop(name)
  rescue StandardError
    nil
  end

  def run_task(name, *args)
    task = Rake::Task[name]
    task.reenable
    task.invoke(*args)
  end

  def create_tenant_site(tenant_name)
    create(:site, name: tenant_name, domain: "#{tenant_name.dasherize}.example.test", tenant_name: tenant_name)
  end

  def within_tenant(site, &block)
    Apartment::Tenant.switch(site.tenant_name) do
      ActsAsTenant.with_tenant(site, &block)
    end
  end

  def in_public(&block)
    Apartment::Tenant.switch('public', &block)
  end

  def public_count(model)
    in_public { model.unscoped.count }
  end

  # site_id is set explicitly: save!(validate: false) skips acts_as_tenant's
  # before_validation tenant assignment, so it would otherwise be nil.
  def seed_sponsor(site, level_name:, sponsor_name:, with_logo: false)
    within_tenant(site) do
      level = SponsorLevel.new(site_id: site.id)
      level[:name] = level_name
      level.save!(validate: false)

      sponsor = Sponsor.new(site_id: site.id, level_id: level.id)
      sponsor[:name] = sponsor_name
      sponsor.logo = Rack::Test::UploadedFile.new(test_png, 'image/png') if with_logo
      sponsor.save!(validate: false)
      sponsor
    end
  end

  def seed_partner(site, type_name:, partner_name:, with_logo: false)
    within_tenant(site) do
      type = PartnerType.new(site_id: site.id)
      type[:name] = type_name
      type.save!(validate: false)

      partner = Partner.new(site_id: site.id, type_id: type.id)
      partner[:name] = partner_name
      partner.logo = Rack::Test::UploadedFile.new(test_png, 'image/png') if with_logo
      partner.save!(validate: false)
      partner
    end
  end

  # A public Sponsor (with its SponsorLevel), for scenarios that need a name the
  # import must reuse or skip.
  def create_public_sponsor(site, level_name:, sponsor_name:)
    in_public do
      level = SponsorLevel.new(site_id: site.id)
      level[:name] = level_name
      level.save!(validate: false)

      sponsor = Sponsor.new(site_id: site.id, level_id: level.id)
      sponsor[:name] = sponsor_name
      sponsor.save!(validate: false)
    end
  end
end
