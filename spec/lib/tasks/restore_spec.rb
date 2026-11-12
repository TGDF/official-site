# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:agenda:restore')

# The local run starts from production's rows rebuilt in local tenant schemas, so a
# backup taken locally must read what production's backup read: the same rows under
# the same ids, each site's rows on the local site of its name, and every upload at
# the size production reported.
#
# rubocop:disable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe 'restoring a dump for the local run' do
  include_context 'with consolidation tenants'

  let(:location) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }
  let(:local_backup) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }
  let(:uploads_root) { Rails.root.join('spec/support/uploads').to_s }
  let(:cdn_root) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }
  let(:other_site) { create_tenant_site('spec_cons_b') }

  # The files as production's CDN serves them: copied aside before the local copy is
  # cleared, then fetched by the url path the dump recorded.
  before do
    allow(URI).to receive(:open) { |url, *| File.open(URI.parse(url).path.sub(uploads_root, cdn_root), 'rb') }
  end

  after { [ location, local_backup, cdn_root ].each { |path| FileUtils.rm_rf(path) } }

  def run(name, at = location)
    out = StringIO.new
    original = $stdout
    $stdout = out
    run_task("tenant_consolidation:agenda:#{name}", at)
    out.string
  rescue SystemExit => e
    "#{out.string}\n[exited #{e.status}]"
  ensure
    $stdout = original
  end

  def dump_at(path)
    TenantConsolidation::Dump.parse(File.read(File.join(path, 'dump.json')))
  end

  def seed_production
    seed_agenda(main_site, subject: 'Opening', speaker_slug: '12', tag_name: '程式', with_avatar: true)
    seed_agenda(other_site, subject: 'Keynote', speaker_slug: 'ada', tag_name: '程式', with_avatar: true)
    run(:backup)
  end

  # What a developer's machine holds before restoring: main's schema empty, and no
  # site at all for the other tenant.
  def leave_production
    FileUtils.cp_r(uploads_root, cdn_root)
    FileUtils.rm_rf(uploads_root)
    within_tenant(main_site) { seeded_models.each { |model| model.unscoped.delete_all } }
    in_public { other_site.destroy! }
  end

  it 'rebuilds the rows and files a local backup then reads as production’s' do
    seed_production
    leave_production

    expect(run(:restore)).to include('Restored 16 row(s) and 6 file(s) into 2 tenant schema(s).')
    expect(run(:backup, local_backup)).to include('Agenda group — 2 site(s)')

    production = dump_at(location)
    local = dump_at(local_backup)
    restored_site = Site.find_by!(tenant_name: 'spec_cons_b')
    production.sites.zip(local.sites).each do |source, copy|
      expect(copy.tenant_name).to eq(source.tenant_name)
      source.models.each do |name, rows|
        expect(copy.rows(name).map(&:id)).to eq(rows.map(&:id))
        copy.rows(name).zip(rows).each do |restored, original|
          expect(restored.attributes.except('site_id')).to eq(original.attributes.except('site_id'))
          expect(restored.upload&.size).to eq(original.upload&.size)
          expect(restored.upload&.versions&.transform_values { |v| v['size'] })
            .to eq(original.upload&.versions&.transform_values { |v| v['size'] })
        end
      end
    end
    within_tenant(restored_site) { expect(Speaker.unscoped.pluck(:site_id)).to eq([ restored_site.id ]) }
  end

  it 'refuses a schema that already holds the group’s rows' do
    seed_production

    expect(run(:restore)).to include('already holding rows: main AgendaDay', '[exited 1]')
  end

  it 'refuses to run anywhere but a developer’s machine' do
    seed_production
    leave_production
    allow(Rails.env).to receive(:local?).and_return(false)

    expect(run(:restore)).to include("restore runs only on a developer's machine", '[exited 1]')
    within_tenant(main_site) { expect(Speaker.unscoped.count).to eq(0) }
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
