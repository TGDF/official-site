# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:backfill_speaker_slugs')

# The task writes across tenant schemas, so it cannot run inside the per-example
# fixture transaction.
# rubocop:disable RSpec/DescribeClass
RSpec.describe 'tenant_consolidation:backfill_speaker_slugs' do
  self.use_transactional_tests = false

  let(:main_site) { Site.find_by(tenant_name: 'main') }

  before { clear_speakers! }
  after { clear_speakers! }

  def clear_speakers!
    Apartment::Tenant.switch('public') { Speaker.unscoped.delete_all }
    in_main { Speaker.unscoped.delete_all }
  end

  def in_main(&block)
    Apartment::Tenant.switch(main_site.tenant_name, &block)
  end

  # site_id is left null on purpose: that is the state of the six tenants this task
  # exists for, and it is what makes `unscoped` necessary inside the task.
  def seed_speaker(slug:)
    in_main do
      speaker = Speaker.new
      speaker[:name] = { 'zh-TW' => 'Speaker' }
      speaker.save!(validate: false)
      # FriendlyId fills a slug in on save, so a legacy slug-less row has to be
      # reproduced by clearing it afterwards.
      speaker.update_column(:slug, slug)
      speaker
    end
  end

  def slug_of(speaker)
    in_main { Speaker.unscoped.find(speaker.id).slug }
  end

  def run_task(*args)
    task = Rake::Task['tenant_consolidation:backfill_speaker_slugs']
    task.reenable
    task.invoke(*args)
  end

  it 'writes the current id into a missing slug' do
    speaker = seed_speaker(slug: nil)

    run_task

    expect(slug_of(speaker)).to(eq(speaker.id.to_s))
  end

  it 'treats an empty string as missing' do
    speaker = seed_speaker(slug: '')

    run_task

    expect(slug_of(speaker)).to(eq(speaker.id.to_s))
  end

  it 'leaves an existing slug alone' do
    speaker = seed_speaker(slug: 'keep-me')

    run_task

    expect(slug_of(speaker)).to(eq('keep-me'))
  end

  it 'writes nothing on a dry run' do
    speaker = seed_speaker(slug: nil)

    run_task('true')

    expect(slug_of(speaker)).to(be_nil)
  end

  # /speakers/{that id} already resolves to the squatter, so there is no URL left to
  # preserve here — the row just needs some free slug.
  it 'steps aside when another speaker already uses that id as its slug' do
    speaker = seed_speaker(slug: nil)
    seed_speaker(slug: speaker.id.to_s)

    run_task

    expect(slug_of(speaker)).to(eq("#{speaker.id}-2"))
  end

  it 'refuses to run once Speaker is served from the public schema' do
    seed_speaker(slug: nil)
    allow(Apartment).to(receive(:excluded_models).and_return(%w[Speaker]))

    expect { run_task }.to(raise_error(SystemExit))
  end
end
# rubocop:enable RSpec/DescribeClass
