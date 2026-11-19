# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:news:verify')

# The news move from backup through the switch to the public schema. Content moves as
# it is, the /uploads/ urls it embeds included, and each author keeps naming the same
# AdminUser.
#
# rubocop:disable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe 'the news move, backup to switch' do
  include_context 'with consolidation tenants'
  include_context 'with a group before its switch', TenantConsolidation::NewsGroup

  let(:location) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }
  let(:other_site) { create_tenant_site('spec_cons_b') }
  let(:author) { create(:admin_user) }
  let(:content) { { 'zh-TW' => '<p>開幕<img src="/uploads/image/file/2/opening.jpg"></p>' } }

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
    run_task("tenant_consolidation:news:#{name}", location)
    out.string
  rescue SystemExit => e
    "#{out.string}\n[exited #{e.status}]"
  ensure
    $stdout = original
  end

  def switch_to_public
    allow(Apartment).to receive(:excluded_models).and_return(Apartment.excluded_models + %w[News])
  end

  it 'moves every news item into public under its site, verified, with its thumbnail in ActiveStorage' do
    seed_news(main_site, slug: 'opening', title: { 'zh-TW' => '開幕' }, content: content, author: author,
                         with_thumbnail: true)
    seed_news(other_site, slug: 'closing', title: { 'en' => 'Closing' }, status: :deleted, with_thumbnail: true)

    expect(run(:backup)).to include('News group — 2 site(s)')
    run(:migrate)
    expect(run(:verify)).to start_with('OK')

    switch_to_public
    expect(run(:verify)).to start_with('OK')

    in_public do
      expect(News.unscoped.pluck(:site_id, :slug, :status))
        .to contain_exactly([ main_site.id, 'opening', 'published' ], [ other_site.id, 'closing', 'deleted' ])
      opening = News.unscoped.find_by(slug: 'opening')
      expect([ opening[:content], opening.author ]).to eq([ content, author ])
      News.unscoped.find_each do |news|
        expect(news.thumbnail_url).to be_a(ActiveStorage::Attached::One).and(be_attached)
      end
    end
  end

  it 'refuses an author that is not an AdminUser, before anything is written' do
    news = seed_news(main_site, slug: 'opening', title: { 'en' => 'Opening' })
    within_tenant(main_site) { News.unscoped.update_all(author_type: 'Speaker', author_id: 1) }

    expect { run(:backup) }
      .to raise_error(TenantConsolidation::Plan::Invalid, /main News##{news.id} has a Speaker author/)
    expect(public_count(News)).to eq(0)
  end

  it 'refuses two items of a site sharing a slug, before anything is written' do
    seed_news(main_site, slug: 'opening', title: { 'en' => 'Opening' })
    seed_news(main_site, slug: 'closing', title: { 'en' => 'Closing' })
    within_tenant(main_site) { News.unscoped.update_all(slug: 'news', site_id: nil) }

    expect { run(:backup) }.to raise_error(TenantConsolidation::Plan::Invalid, /main News #\d+ #\d+ share the slug "news"/)
    expect(public_count(News)).to eq(0)
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
