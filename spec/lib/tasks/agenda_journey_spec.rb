# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:agenda:verify')

# The agenda move from backup through the switch to the public schema: eight tables
# whose foreign keys must land on their own site's new rows, tags merged into one
# shared vocabulary, and every speaker keeping the slug its links resolve by.
#
# rubocop:disable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe 'the agenda move, backup to switch' do
  include_context 'with consolidation tenants'

  let(:location) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }
  let(:other_site) { create_tenant_site('spec_cons_b') }

  # CarrierWave stores files locally in test, where an upload's url is the asset host
  # in front of its path.
  before { allow(URI).to receive(:open) { |url| File.open(URI.parse(url).path, 'rb') } }

  after { FileUtils.rm_rf(location) }

  # A task that finds a problem exits non-zero; that exit is kept in the returned
  # output, where the expectation that follows can fail on it, instead of escaping
  # the example and ending the whole run.
  def run(name)
    out = StringIO.new
    original = $stdout
    $stdout = out
    run_task("tenant_consolidation:agenda:#{name}", location)
    out.string
  rescue SystemExit => e
    "#{out.string}\n[exited #{e.status}]"
  ensure
    $stdout = original
  end

  def switch_to_public
    allow(Apartment).to receive(:excluded_models)
      .and_return(Apartment.excluded_models + TenantConsolidation::AgendaGroup::TARGETS)
  end

  def public_agenda(site)
    Agenda.unscoped.find_by!(site_id: site.id)
  end

  it 'moves each site’s agenda graph onto its own new rows, sharing one tag, verified' do
    seed_agenda(main_site, subject: 'Opening', speaker_slug: '12', tag_name: '程式', with_avatar: true)
    seed_agenda(other_site, subject: 'Keynote', speaker_slug: 'ada', tag_name: '程式', with_avatar: true)

    expect(run(:backup)).to include('Agenda group — 2 site(s)', "{\"zh-TW\":\"程式\"} ← main#")
    run(:migrate)
    expect(run(:verify)).to start_with('OK')

    switch_to_public
    expect(run(:verify)).to start_with('OK')

    in_public do
      tag = AgendaTag.unscoped.sole
      expect(tag.site_id).to be_nil

      [ [ main_site, '12' ], [ other_site, 'ada' ] ].each do |site, slug|
        ActsAsTenant.with_tenant(site) do
          agenda = public_agenda(site)
          expect([ agenda.time.site_id, agenda.time.day.site_id, agenda.room.site_id ]).to eq([ site.id ] * 3)
          expect(agenda.speakers.map { |speaker| [ speaker.site_id, speaker.slug ] }).to eq([ [ site.id, slug ] ])
          expect(agenda.speakers.sole.avatar_attachment).to be_attached
          expect([ agenda[:begin_at], agenda.tags.to_a ]).to eq([ '2026-07-16 16:30', [ tag ] ])
        end
      end
    end
  end

  it 'reports a shared tag the plan does not account for' do
    seed_agenda(main_site, subject: 'Opening', speaker_slug: '12', tag_name: '程式')
    run(:backup)
    run(:migrate)
    in_public { AgendaTag.create!(name: '視覺') }

    expect(run(:verify)).to include('public holds 2 AgendaTag row(s), the plan has 1 shared', '[exited 1]')
  end

  it 'leaves out a tagging whose tag is gone, and lists it' do
    agenda = seed_agenda(main_site, subject: 'Opening', speaker_slug: '12', tag_name: '視覺')
    within_tenant(main_site) { AgendaTag.unscoped.delete_all }

    expect(run(:backup)).to match(/whose tag or agenda is gone \(left out\) \(1\)\n  main AgendasTagging#\d+ → Agenda##{agenda.id}/)
    run(:migrate)
    expect(run(:verify)).to start_with('OK')
    expect(public_count(AgendasTagging)).to eq(0)
  end

  it 'refuses a speaker without a slug, before anything is written' do
    seed_agenda(main_site, subject: 'Opening', speaker_slug: '12')
    within_tenant(main_site) { Speaker.unscoped.update_all(slug: nil) }

    expect { run(:backup) }.to raise_error(TenantConsolidation::Plan::Invalid, /main Speaker #\d+ has no slug/)
    expect(public_count(Speaker)).to eq(0)
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
