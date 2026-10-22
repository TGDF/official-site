# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:game:verify')

# The game move from backup through the switch to the public schema. Each thumbnail
# is downloaded from the file CarrierWave stored, so the bytes ActiveStorage keeps are
# the bytes the dump recorded.
#
# rubocop:disable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe 'the game move, backup to switch' do
  include_context 'with consolidation tenants'

  let(:location) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }
  let(:night_market_site) { create_tenant_site('spec_cons_b') }

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
    run_task("tenant_consolidation:game:#{name}", location)
    out.string
  rescue SystemExit => e
    "#{out.string}\n[exited #{e.status}]"
  ensure
    $stdout = original
  end

  def switch_to_public
    allow(Apartment).to receive(:excluded_models).and_return(Apartment.excluded_models + %w[Game])
  end

  def id_map
    JSON.parse(File.read(File.join(location, 'id_map.json')))
  end

  it 'moves every game into public under its own kind and site, verified, with its thumbnail in ActiveStorage' do
    seed_game(main_site, name: { 'en' => 'Lumen', 'zh-TW' => '流明' }, as: IndieSpace::Game, with_thumbnail: true)
    seed_game(night_market_site, name: { 'zh-TW' => '夜市' }, as: NightMarket::Game, with_thumbnail: true)

    expect(run(:backup)).to include('Game group — 2 site(s)')
    run(:migrate)
    expect(run(:verify)).to start_with('OK')

    switch_to_public
    expect(run(:verify)).to start_with('OK')

    in_public do
      expect(IndieSpace::Game.unscoped.pluck(:site_id)).to eq([ main_site.id ])
      expect(NightMarket::Game.unscoped.pluck(:site_id)).to eq([ night_market_site.id ])
      Game.unscoped.find_each do |game|
        expect(game.thumbnail_url).to be_a(ActiveStorage::Attached::One).and(be_attached)
      end

      night_market_game = NightMarket::Game.unscoped.first
      expect(night_market_game[:name]).to eq({ 'zh-TW' => '夜市' })
      expect(Mobility.with_locale(:en) { night_market_game.name }).to eq('夜市')
    end
  end

  # Recovery after the switch deploy: the switch is reverted, then rollback[game]
  # runs, by which time pages have already made variants of the thumbnails.
  it 'leaves no thumbnail or variant file behind when rolled back after the switch' do
    seed_game(main_site, name: { 'zh-TW' => '流明' }, as: IndieSpace::Game, with_thumbnail: true)
    stored_before = stored_files
    run(:backup)
    run(:migrate)

    switch_to_public
    in_public { Game.unscoped.sole.thumbnail_url(:thumb).processed }
    allow(Apartment).to receive(:excluded_models).and_call_original
    silently { run_task('tenant_consolidation:rollback', 'game') }

    expect([ ActiveStorage::Blob.count, stored_files - stored_before ]).to eq([ 0, [] ])
  end

  it 'takes a thumbnail over from its largest version when the original is gone' do
    game = seed_game(night_market_site, name: { 'zh-TW' => '迷霧國度' }, as: NightMarket::Game, with_thumbnail: true)
    large_path = within_tenant(night_market_site) do
      thumbnail = Game.unscoped.find(game.id).thumbnail
      FileUtils.rm(thumbnail.path)
      FileUtils.cp(Rails.root.join('spec/support/sliders/slide_1.jpg'), thumbnail.large.path)
      thumbnail.large.path
    end

    expect(run(:backup)).to match(/original being gone \(1\)\n  spec_cons_b Game##{game.id} thumbnail ← large /)
    run(:migrate)
    expect(run(:verify)).to start_with('OK')

    expect(id_map.dig('stand_ins', 'spec_cons_b')).to contain_exactly(hash_including('version' => 'large'))
    expect(in_public { Game.unscoped.first.thumbnail_attachment.byte_size }).to eq(File.size(large_path))
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
