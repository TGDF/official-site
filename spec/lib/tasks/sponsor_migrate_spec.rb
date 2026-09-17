# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:sponsor:migrate')

# Integration examples drive a whole backup → migrate run and assert several outcomes
# of it, so the per-example RSpec metric cops are relaxed for this file.
# rubocop:disable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe 'tenant_consolidation:sponsor:migrate' do
  include_context 'with consolidation tenants'

  let(:location) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }
  let(:dump_path) { File.join(location, 'dump.json') }

  # CarrierWave uses local file storage in test, so the logo URL is not HTTP-fetchable.
  before { allow(URI).to receive(:open) { File.open(test_png, 'rb') } }

  after { FileUtils.rm_rf(location) }

  def backup
    silently { run_task('tenant_consolidation:sponsor:backup', location) }
  end

  def migrate
    silently { run_task('tenant_consolidation:sponsor:migrate', location) }
  end

  def edit_dump
    data = JSON.parse(File.read(dump_path))
    yield data
    File.write(dump_path, data.to_json)
  end

  def id_map
    JSON.parse(File.read(File.join(location, 'id_map.json')))
  end

  def public_sponsor(site)
    in_public { Sponsor.unscoped.find_by(site_id: site.id) }
  end

  describe 'sponsors and their levels' do
    let(:other_site) { create_tenant_site('spec_cons_b') }

    before do
      seed_sponsor(main_site, level_name: { 'en' => 'Gold', 'zh-TW' => '金' },
                              sponsor_name: { 'en' => 'Acme', 'zh-TW' => '艾克米' }, with_logo: true)
      seed_sponsor(other_site, level_name: { 'en' => 'Silver' }, sponsor_name: { 'en' => 'Globex' })
      backup
      migrate
    end

    it 'imports every site\'s rows under the importing site, each sponsor under its own level' do
      in_public do
        expect(Sponsor.unscoped.pluck(:site_id)).to contain_exactly(main_site.id, other_site.id)
        Sponsor.unscoped.find_each do |sponsor|
          expect(SponsorLevel.unscoped.find(sponsor.level_id).site_id).to eq(sponsor.site_id)
        end
      end
    end

    it 'keeps every locale, the source timestamps and the CarrierWave marker' do
      source = within_tenant(main_site) { Sponsor.unscoped.sole }
      imported = public_sponsor(main_site)

      expect(imported[:name]).to eq({ 'en' => 'Acme', 'zh-TW' => '艾克米' })
      expect(imported.created_at).to eq(source.created_at)
      expect(imported[:logo]).to eq(source[:logo])
    end

    it 'attaches the logo to ActiveStorage at the source size' do
      expect(public_sponsor(main_site).logo_attachment.byte_size).to eq(File.size(test_png))
    end

    it 'writes an id map from each dumped row to its public row' do
      source = within_tenant(main_site) { Sponsor.unscoped.sole }

      expect(id_map.dig('sites', 'main', 'Sponsor', source.id.to_s)).to eq(public_sponsor(main_site).id)
    end

    it 'refuses a second run onto the rows the first one wrote' do
      expect { migrate }.to raise_error(TenantConsolidation::SponsorGroup::Import::Invalid, /rollback\[sponsor\]/)
    end
  end

  describe 'partners folding into sponsors' do
    it 'turns a PartnerType into a SponsorLevel of the same name, and its Partner into a Sponsor under it' do
      partner = seed_partner(main_site, type_name: { 'en' => 'Bronze', 'zh-TW' => '銅' },
                                        partner_name: { 'en' => 'Initech', 'zh-TW' => '創投' })
      backup
      migrate

      sponsor = public_sponsor(main_site)
      expect(sponsor[:name]).to eq({ 'en' => 'Initech', 'zh-TW' => '創投' })
      expect(in_public { SponsorLevel.unscoped.find(sponsor.level_id)[:name] }).to eq({ 'en' => 'Bronze', 'zh-TW' => '銅' })
      expect(id_map.dig('sites', 'main', 'Partner', partner.id.to_s)).to eq(sponsor.id)
    end

    it 'reuses a SponsorLevel of the same site that already has the name' do
      seed_sponsor(main_site, level_name: { 'en' => 'Bronze' }, sponsor_name: { 'en' => 'Existing' })
      seed_partner(main_site, type_name: { 'en' => 'Bronze' }, partner_name: { 'en' => 'Initech' })
      backup
      migrate

      expect(public_count(SponsorLevel)).to eq(1)
      expect(public_count(Sponsor)).to eq(2)
    end

    it 'skips a partner whose name a sponsor of the same site holds, and records it' do
      seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Initech' })
      partner = seed_partner(main_site, type_name: { 'en' => 'Bronze' }, partner_name: { 'en' => 'Initech' })
      backup

      expect { run_task('tenant_consolidation:sponsor:migrate', location) }
        .to output(/main: .*skipped Partner ##{partner.id} /).to_stdout
      expect(public_count(Sponsor)).to eq(1)
      expect(id_map.dig('skipped', 'main', 'Partner')).to eq([ partner.id ])
    end

    it "corrects 2023tgdf's swapped PartnerType label on the level it becomes" do
      site = create_tenant_site('2023tgdf')
      seed_partner(site, type_name: { 'en' => 'Supporting Partners', 'zh-TW' => '協辦單位' },
                         partner_name: { 'en' => 'Initech' })
      backup
      migrate

      level = in_public { SponsorLevel.unscoped.find_by(site_id: site.id) }
      expect(level[:name]).to eq({ 'en' => 'Supporting Partners', 'zh-TW' => '合作單位' })
    end
  end

  describe 'refusing before anything is written' do
    before { seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' }) }

    it 'refuses a logo whose source file is gone' do
      sponsor = seed_sponsor(main_site, level_name: { 'en' => 'Silver' }, sponsor_name: { 'en' => 'Lost' },
                                        with_logo: true)
      within_tenant(main_site) { FileUtils.rm(Sponsor.unscoped.find(sponsor.id).logo.path) }
      backup

      expect { migrate }.to raise_error(TenantConsolidation::SponsorGroup::Import::Invalid, /logo source is missing/)
      expect(public_count(Sponsor)).to eq(0)
    end

    it 'refuses a dumped tenant that has no Site here' do
      site = create_tenant_site('spec_cons_b')
      seed_sponsor(site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Elsewhere' })
      backup
      in_public { Site.where(id: site.id).delete_all }

      expect { migrate }.to raise_error(TenantConsolidation::SponsorGroup::Import::Invalid, /no Site here for dumped tenant spec_cons_b/)
      expect(public_count(Sponsor)).to eq(0)
    end

    it 'refuses a sponsor whose level is not in the dump' do
      backup
      edit_dump { |data| data['sites'].find { |s| s['tenant_name'] == 'main' }['models']['Sponsor'][0]['attributes']['level_id'] = 999 }

      expect { migrate }.to raise_error(TenantConsolidation::SponsorGroup::Import::Invalid, /SponsorLevel#999/)
      expect(public_count(SponsorLevel)).to eq(0)
    end

    it 'refuses an ActiveStorage attachment already sitting on a Sponsor id' do
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('x'), filename: 'x.png')
      ActiveStorage::Attachment.insert!(
        { name: 'logo_attachment', record_type: 'Sponsor', record_id: 999, blob_id: blob.id, created_at: Time.current }
      )
      backup

      expect { migrate }.to raise_error(TenantConsolidation::SponsorGroup::Import::Invalid, /already sit on Sponsor ids/)
    end
  end

  it 'writes the rows of every site or of none' do
    seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' })
    seed_sponsor(create_tenant_site('spec_cons_b'), level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Globex' })
    backup
    allow(TenantConsolidation::Records).to receive(:verify_translations_preserved).and_call_original
    allow(TenantConsolidation::Records).to receive(:verify_translations_preserved)
      .with(hash_including('name' => { 'en' => 'Globex' }), anything, anything).and_raise('boom')

    expect { migrate }.to raise_error('boom')
    expect([ public_count(SponsorLevel), public_count(Sponsor) ]).to eq([ 0, 0 ])
  end

  it 'names the attached logo exactly as CarrierWave stored it, even when the name is not ASCII' do
    seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Initech' },
                            with_logo: true, logo_name: '創投標誌.png')
    backup
    migrate

    expect(public_sponsor(main_site).logo_attachment.filename.to_s).to eq('創投標誌.png')
  end

  it 'keeps the rows and the id map when a logo download fails, so verify can name what is missing' do
    seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' }, with_logo: true)
    backup
    allow(URI).to receive(:open).and_raise(Errno::ECONNREFUSED)

    expect { migrate }.to raise_error(Errno::ECONNREFUSED)
    expect(public_count(Sponsor)).to eq(1)
    expect(id_map.dig('sites', 'main', 'Sponsor').size).to eq(1)
  end

  it 'can run again after rollback[sponsor] clears what it wrote' do
    seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' }, with_logo: true)
    partner = seed_partner(main_site, type_name: { 'en' => 'Bronze' }, partner_name: { 'en' => 'Initech' })
    backup
    migrate
    silently { run_task('tenant_consolidation:rollback', 'sponsor') }

    expect([ public_count(SponsorLevel), public_count(Sponsor) ]).to eq([ 0, 0 ])
    expect { migrate }.not_to raise_error
    expect(id_map.dig('sites', 'main', 'Partner', partner.id.to_s)).to be_present
  end

  it 'takes the site from the importing database, not from the dump' do
    seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' })
    backup
    edit_dump do |data|
      data['sites'].find { |s| s['tenant_name'] == 'main' }['models']['Sponsor'][0]['attributes']['site_id'] = 12_345
    end
    migrate

    expect(in_public { Sponsor.unscoped.sole.site_id }).to eq(main_site.id)
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
