# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:sponsor:verify')

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'tenant_consolidation:sponsor:verify' do
  include_context 'with consolidation tenants'

  let(:location) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }
  let(:site_2023) { create_tenant_site('2023tgdf') }

  before do
    allow(URI).to receive(:open) { File.open(test_png, 'rb') }
    seed_sponsor(main_site, level_name: { 'en' => 'Gold', 'zh-TW' => '金' },
                            sponsor_name: { 'en' => 'Acme', 'zh-TW' => '艾克米' }, with_logo: true)
    seed_partner(site_2023, type_name: { 'en' => 'Supporting Partners', 'zh-TW' => '協辦單位' },
                            partner_name: { 'en' => 'Initech' }, with_logo: true)
    silently do
      run_task('tenant_consolidation:sponsor:backup', location)
      run_task('tenant_consolidation:sponsor:migrate', location)
    end
  end

  after { FileUtils.rm_rf(location) }

  def verify
    run_task('tenant_consolidation:sponsor:verify', location)
  end

  def reports(pattern)
    output(pattern).to_stdout.and(raise_error(SystemExit))
  end

  def acme = in_public { Sponsor.unscoped.find_by(site_id: main_site.id) }

  # verify exits non-zero on any problem, so passing is not raising.
  it 'passes a clean run, merged partners and corrected labels included' do
    expect { silently { verify } }.not_to raise_error
  end

  it 'names a row filed under another site' do
    in_public { acme.update_column(:site_id, site_2023.id) }

    expect { verify }.to reports(/main Sponsor#\d+ belongs to site #{site_2023.id}, expected #{main_site.id}/)
  end

  it 'names a sponsor whose logo is not in ActiveStorage' do
    in_public { acme.logo_attachment.purge }

    expect { verify }.to reports(/main Sponsor#\d+ has no logo in ActiveStorage/)
  end

  it 'names a logo whose size differs from the source' do
    in_public { acme.logo_attachment.blob.update_column(:byte_size, 1) }

    expect { verify }.to reports(/logo is 1 bytes, the source was #{File.size(test_png)}/)
  end

  it 'names a column that differs from the dump' do
    in_public { acme.update_column(:url, 'https://changed.example') }

    expect { verify }.to reports(%r{main Sponsor#\d+\.url is "https://changed\.example", expected nil})
  end

  it 'names a changed timestamp on a row that carried no logo' do
    in_public { SponsorLevel.unscoped.find_by(site_id: main_site.id).update_column(:updated_at, 1.day.ago) }

    expect { verify }.to reports(/main SponsorLevel#\d+\.updated_at is /)
  end

  it 'names a lost locale' do
    in_public { acme.update_column(:name, { 'en' => 'Acme' }) }

    expect { verify }.to reports(/main Sponsor#\d+\.name is .*, expected .*艾克米/)
  end

  it 'names a sponsor under the wrong level' do
    in_public { acme.update_column(:level_id, nil) }

    expect { verify }.to reports(/main Sponsor#\d+ is under level nil, expected \d+/)
  end

  it 'names a dumped row that has no public row' do
    in_public { acme.destroy! }

    expect { verify }.to reports(/main Sponsor#\d+ has no public Sponsor/)
  end

  it 'names a public row the plan does not account for' do
    in_public { Sponsor.new(site_id: main_site.id, level_id: acme.level_id).save!(validate: false) }

    expect { verify }.to reports(/main: public holds 2 Sponsor row\(s\), the plan has 1/)
  end

  it "names 2023tgdf's level if it kept the swapped label" do
    in_public do
      level = SponsorLevel.unscoped.find_by(site_id: site_2023.id)
      level.update_column(:name, { 'en' => 'Supporting Partners', 'zh-TW' => '協辦單位' })
    end

    expect { verify }.to reports(/2023tgdf PartnerType#\d+\.name is .*協辦單位.*, expected .*合作單位/)
  end
end
# rubocop:enable RSpec/DescribeClass
