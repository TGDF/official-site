# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe TenantConsolidation::Dump do
  include_context 'with consolidation tenants'

  let(:models) { %w[SponsorLevel Sponsor] }
  let(:uploads) { { 'Sponsor' => :logo } }

  def collect
    described_class.collect(group: 'sponsor', models: models, uploads: uploads)
  end

  def round_trip(dump)
    described_class.parse(dump.to_json)
  end

  describe '.collect' do
    it 'files each row under the site it came from, with its source id' do
      sponsor = seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' })

      site = collect.sites.find { |s| s.tenant_name == 'main' }

      expect([ site.site_id, site.rows('Sponsor').sole.id ]).to eq([ main_site.id, sponsor.id ])
    end

    it 'keeps every column, nil included' do
      seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' })

      row = collect.sites.find { |s| s.tenant_name == 'main' }.rows('Sponsor').sole

      expect(row.attributes).to include('name' => { 'en' => 'Acme' }, 'url' => nil)
        .and(satisfy { |attrs| attrs.keys.sort == Sponsor.column_names.sort })
    end

    it 'records where each upload lives and how large it is' do
      seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' }, with_logo: true)

      upload = collect.sites.find { |s| s.tenant_name == 'main' }.rows('Sponsor').sole.upload

      expect(upload).to have_attributes(field: 'logo', url: end_with('TGDF.png'),
                                        path: end_with('TGDF.png'), size: File.size(test_png))
    end

    it 'records no upload for a row without a file' do
      seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' })

      expect(collect.sites.find { |s| s.tenant_name == 'main' }.rows('Sponsor').sole.upload).to be_nil
    end

    it 'refuses a model already served from the public schema' do
      expect { described_class.collect(group: 'slider', models: %w[Slider]) }
        .to raise_error(described_class::Invalid, /Slider already in the public schema/)
    end
  end

  describe 'serialization' do
    it 'keeps timestamps to the microsecond' do
      sponsor = seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' })
      stored = within_tenant(main_site) { Sponsor.unscoped.find(sponsor.id).created_at }

      row = round_trip(collect).sites.find { |s| s.tenant_name == 'main' }.rows('Sponsor').sole

      expect(Time.iso8601(row.attributes['created_at'])).to eq(stored)
      expect(stored.usec).not_to eq(0)
    end

    it 'keeps every locale of a translated column' do
      seed_sponsor(main_site, level_name: { 'en' => 'Gold', 'zh-TW' => '金' }, sponsor_name: { 'en' => 'Acme' })

      level = round_trip(collect).sites.find { |s| s.tenant_name == 'main' }.rows('SponsorLevel').sole

      expect(level.attributes['name']).to eq({ 'en' => 'Gold', 'zh-TW' => '金' })
    end

    it 'refuses a dump that lost rows on the way' do
      seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' })
      data = JSON.parse(collect.to_json)
      data['sites'].find { |s| s['tenant_name'] == 'main' }['models']['Sponsor'].clear

      expect { described_class.parse(data.to_json) }
        .to raise_error(described_class::Invalid, /incomplete/)
    end

    it 'refuses a format it does not know' do
      data = JSON.parse(collect.to_json).merge('format' => 99)

      expect { described_class.parse(data.to_json) }
        .to raise_error(described_class::Invalid, /unsupported dump format 99/)
    end
  end

  describe TenantConsolidation::Dump::Upload do
    it 'counts a source fog reports as empty or unknown as missing' do
      expect(described_class.new(field: 'logo', url: 'u', path: 'p', size: 0)).to be_missing
      expect(described_class.new(field: 'logo', url: 'u', path: 'p', size: nil)).to be_missing
      expect(described_class.new(field: 'logo', url: 'u', path: 'p', size: 12)).not_to be_missing
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
