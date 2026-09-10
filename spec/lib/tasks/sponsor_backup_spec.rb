# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:sponsor:backup')

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'tenant_consolidation:sponsor:backup' do
  include_context 'with consolidation tenants'

  let(:location) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }

  after { FileUtils.rm_rf(location) }

  def backup
    run_task('tenant_consolidation:sponsor:backup', location)
  end

  def written_dump
    TenantConsolidation::Dump.parse(File.read(File.join(location, 'dump.json')))
  end

  it 'writes every sponsor-group model of every site into the run' do
    seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' })
    seed_partner(main_site, type_name: { 'en' => 'Bronze' }, partner_name: { 'en' => 'Initech' })
    silently { backup }

    expect(written_dump.counts.fetch('main'))
      .to eq('SponsorLevel' => 1, 'Sponsor' => 1, 'PartnerType' => 1, 'Partner' => 1)
  end

  it 'reports a logo whose source file is gone' do
    sponsor = seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Acme' },
                                      with_logo: true)
    within_tenant(main_site) { FileUtils.rm(Sponsor.unscoped.find(sponsor.id).logo.path) }

    expect { backup }.to output(/source file is missing \(1\)\n  main Sponsor##{sponsor.id} /).to_stdout
  end

  it 'reports an ActiveStorage attachment already sitting on a Sponsor id' do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('x'), filename: 'x.png')
    ActiveStorage::Attachment.insert!(
      { name: 'logo_attachment', record_type: 'Sponsor', record_id: 999, blob_id: blob.id, created_at: Time.current }
    )

    expect { backup }.to output(%r{Leftover ActiveStorage attachments on Sponsor/Partner \(1\)\n  Sponsor: 1}).to_stdout
  end

  it 'reports a partner that the import will skip for sharing a sponsor name' do
    seed_sponsor(main_site, level_name: { 'en' => 'Gold' }, sponsor_name: { 'en' => 'Initech' })
    partner = seed_partner(main_site, type_name: { 'en' => 'Bronze' }, partner_name: { 'en' => 'Initech' })

    expect { backup }.to output(/skipped on import\) \(1\)\n  main Partner##{partner.id} /).to_stdout
  end

  it "reports 2023tgdf's swapped PartnerType label with the label it will get" do
    site = create_tenant_site('2023tgdf')
    seed_partner(site, type_name: { 'en' => 'Supporting Partners', 'zh-TW' => '協辦單位' },
                       partner_name: { 'en' => 'Initech' })

    expect { backup }.to output(/corrected on import \(1\)\n  2023tgdf PartnerType#\d+ .*協辦單位.* → .*合作單位/).to_stdout
  end

  it 'refuses once the group is served from the public schema' do
    allow(Apartment).to receive(:excluded_models).and_return(%w[Site Sponsor SponsorLevel])

    expect { backup }.to raise_error(TenantConsolidation::Dump::Invalid)
  end
end
# rubocop:enable RSpec/DescribeClass
