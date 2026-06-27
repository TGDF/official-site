# frozen_string_literal: true

require 'rails_helper'

# Load the rake tasks once when this spec file is required (idempotent guard).
Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:consolidate')

# Integration tests for the tenant consolidation rake task. Assertions mirror the
# "Testing the Consolidation" risk table in docs/tenant_consolidation.md:
#   FK ID remapping, Mobility translations, asset transfer (byte size), re-run guard,
#   partner guard, attachment polymorphic guard, cross-tenant uniqueness.
#
# Integration examples legitimately drive a whole flow and assert several outcomes,
# so the per-example RSpec metric cops are relaxed for this file.
# rubocop:disable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe 'tenant_consolidation rake tasks' do
  # This spec issues DDL (CREATE/DROP SCHEMA via Apartment) and the task switches
  # schemas, which cannot run inside the per-example fixture transaction — disable it
  # and clean up manually (drop created schemas + truncate public-schema output).
  self.use_transactional_tests = false

  let(:test_png) { Rails.root.join('spec/support/brands/logos/TGDF.png') }
  let(:main_site) { Site.find_by(tenant_name: 'main') }
  let(:extra_tenants) { %w[spec_cons_b spec_cons_asset] }

  # Transactions are off, so created Site records + public-schema output persist —
  # reset both before and after each example. A dangling Site whose schema is dropped
  # would otherwise break the task's Site.find_each on the next example.
  before { reset_consolidation_state! }
  after { reset_consolidation_state! }

  def reset_consolidation_state!
    in_public do
      [ Sponsor, SponsorLevel, Attachment ].each { |model| model.unscoped.delete_all }
      Site.where(tenant_name: extra_tenants).delete_all
    end
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

  def within_tenant(site, &block)
    Apartment::Tenant.switch(site.tenant_name) do
      ActsAsTenant.with_tenant(site, &block)
    end
  end

  def in_public(&block)
    Apartment::Tenant.switch('public', &block)
  end

  # Seed a SponsorLevel + Sponsor in a tenant. Names are raw JSONB (all locales).
  def seed_sponsor(site, level_name:, sponsor_name:, with_logo: false)
    within_tenant(site) do
      level = SponsorLevel.new
      level[:name] = level_name
      level.save!(validate: false)

      sponsor = Sponsor.new
      sponsor[:name] = sponsor_name
      sponsor.level_id = level.id
      sponsor.logo = Rack::Test::UploadedFile.new(test_png, 'image/png') if with_logo
      sponsor.save!(validate: false)
      { level_id: level.id, sponsor_id: sponsor.id }
    end
  end

  describe 'guard rails' do
    it 'aborts when no group is given' do
      expect { run_task('tenant_consolidation:consolidate') }.to raise_error(SystemExit)
    end

    it 'aborts the retired partner group (use merge instead)' do
      expect { run_task('tenant_consolidation:consolidate', 'partner') }.to raise_error(SystemExit)
    end

    it 'aborts attachment consolidation when a polymorphic record_id is set' do
      within_tenant(main_site) do
        Attachment.new(record_type: 'Foo', record_id: 123, file: 'x.png').save!(validate: false)
      end
      expect { run_task('tenant_consolidation:consolidate', 'attachment') }.to raise_error(SystemExit)
    end

    it 'aborts news consolidation when author_type is not AdminUser' do
      within_tenant(main_site) do
        news = News.new
        news[:title] = { 'en' => 'T' }
        news.slug = 'spec-news'
        news.author_type = 'Foo'
        news.author_id = 1
        news.save!(validate: false)
      end
      expect { run_task('tenant_consolidation:consolidate', 'news') }.to raise_error(SystemExit)
    end
  end

  describe 'consolidate[sponsor] across two tenants (no uploads)' do
    let(:other_site) do
      create(:site, name: 'Other', domain: 'other.example.test', tenant_name: 'spec_cons_b')
    end

    before do
      seed_sponsor(main_site,
                   level_name: { 'en' => 'Gold', 'zh-TW' => '金' },
                   sponsor_name: { 'en' => 'Acme', 'zh-TW' => '艾克米' })
      seed_sponsor(other_site,
                   level_name: { 'en' => 'Silver', 'zh-TW' => '銀' },
                   sponsor_name: { 'en' => 'Globex', 'zh-TW' => '環球' })
      run_task('tenant_consolidation:consolidate', 'sponsor')
    end

    it 'migrates every tenant\'s rows into public with the correct site_id' do
      in_public do
        expect(SponsorLevel.unscoped.count).to eq(2)
        expect(Sponsor.unscoped.count).to eq(2)
        expect(Sponsor.unscoped.pluck(:site_id)).to contain_exactly(main_site.id, other_site.id)
      end
    end

    it 'remaps sponsor.level_id to each sponsor\'s OWN migrated level (no stale/cross-tenant id)' do
      in_public do
        Sponsor.unscoped.find_each do |sponsor|
          level = SponsorLevel.unscoped.find_by(id: sponsor.level_id)
          expect(level).to be_present
          expect(level.site_id).to eq(sponsor.site_id)
        end
      end
    end

    it 'preserves all Mobility locales' do
      in_public do
        acme = Sponsor.unscoped.find_by(site_id: main_site.id)
        expect(acme[:name].keys).to match_array(%w[en zh-TW])
        expect(acme[:name]['zh-TW']).to eq('艾克米')
      end
    end

    it 'aborts a re-run onto a non-empty public target' do
      expect { run_task('tenant_consolidation:consolidate', 'sponsor') }.to raise_error(SystemExit)
    end

    it 'leaves the id sequence usable (a fresh insert does not hit a duplicate key)' do
      in_public do
        ActsAsTenant.with_tenant(main_site) do
          level = SponsorLevel.new
          level[:name] = { 'en' => 'Fresh', 'zh-TW' => '新' }
          expect { level.save!(validate: false) }.not_to raise_error
          expect(level.id).to be_present
        end
      end
    end
  end

  describe 'consolidate[sponsor] dry run' do
    before do
      seed_sponsor(main_site,
                   level_name: { 'en' => 'Gold', 'zh-TW' => '金' },
                   sponsor_name: { 'en' => 'Acme', 'zh-TW' => '艾克米' })
    end

    it 'writes nothing to the public schema' do
      run_task('tenant_consolidation:consolidate', 'sponsor', 'true')
      in_public do
        expect(SponsorLevel.unscoped.count).to eq(0)
        expect(Sponsor.unscoped.count).to eq(0)
      end
    end
  end

  describe 'consolidate[sponsor] asset transfer' do
    let(:asset_site) do
      create(:site, name: 'Asset', domain: 'asset.example.test', tenant_name: 'spec_cons_asset')
    end

    it 'attaches the logo to ActiveStorage with a matching byte size, even for a record invalid under current validations' do
      # Name only in :en — under the default locale (zh-TW) the Sponsor is invalid.
      # ActiveStorage#attach auto-saves only a valid record, so this also exercises the
      # task's validate:false persistence (a legacy row predating a tightened rule must
      # still get its attachment, not silently lose it while the in-memory check passes).
      seed_sponsor(asset_site,
                   level_name: { 'en' => 'Gold' },
                   sponsor_name: { 'en' => 'WithLogo' },
                   with_logo: true)

      # CarrierWave uses local file storage in test, so the download URL is not
      # HTTP-fetchable — return the on-disk test image for the asset download.
      allow(URI).to receive(:open) { File.open(test_png, 'rb') }

      run_task('tenant_consolidation:consolidate', 'sponsor')

      in_public do
        sponsor = Sponsor.unscoped.find_by(site_id: asset_site.id)
        expect(sponsor.logo_attachment).to be_attached
        expect(sponsor.logo_attachment.byte_size).to eq(File.size(test_png))
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
