# frozen_string_literal: true

require 'rails_helper'
require 'aws-sdk-s3'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:sponsor:verify')

# The run as production makes it: backup picks its own location in the bucket,
# migrate and verify work from that location, and after the switch to the public
# schema the logos are served from ActiveStorage. Each step has its own spec; this
# one walks them in order, so a seam between two green steps cannot hide.
#
# rubocop:disable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
RSpec.describe 'the sponsor move, backup to switch' do
  include_context 'with consolidation tenants'

  let(:bucket) { 'files.example.test' }
  let(:objects) { {} }
  let(:s3) do
    Aws::S3::Client.new(stub_responses: true).tap do |client|
      client.stub_responses(:put_object, lambda { |context|
        objects[context.params[:key]] = context.params[:body]
        {}
      })
      client.stub_responses(:get_object, lambda { |context|
        objects.key?(context.params[:key]) ? { body: objects[context.params[:key]] } : 'NoSuchKey'
      })
    end
  end
  let(:site_2023) { create_tenant_site('2023tgdf') }

  before do
    allow(Settings.s3).to receive_messages(enabled: true, bucket: bucket)
    allow(Aws::S3::Client).to receive(:new).and_return(s3)
    allow(URI).to receive(:open) { File.open(test_png, 'rb') }

    seed_sponsor(main_site, level_name: { 'en' => 'Gold', 'zh-TW' => '金' },
                            sponsor_name: { 'en' => 'Acme', 'zh-TW' => '艾克米' }, with_logo: true)
    seed_partner(site_2023, type_name: { 'en' => 'Supporting Partners', 'zh-TW' => '協辦單位' },
                            partner_name: { 'en' => 'Initech' }, with_logo: true)
  end

  # A task that finds a problem exits non-zero; that exit is kept in the returned
  # output, where the expectation that follows can fail on it, instead of escaping
  # the example and ending the whole run.
  def run(name, *args)
    out = StringIO.new
    original = $stdout
    $stdout = out
    run_task("tenant_consolidation:sponsor:#{name}", *args)
    out.string
  rescue SystemExit => e
    "#{out.string}\n[exited #{e.status}]"
  ensure
    $stdout = original
  end

  def switch_to_public
    allow(Apartment).to receive(:excluded_models).and_return(Apartment.excluded_models + %w[SponsorLevel Sponsor])
  end

  it 'moves every sponsor and partner into public, verified, with its logo in ActiveStorage' do
    location = run(:backup)[%r{Dump written to (s3://\S+)}, 1]
    expect(location).to start_with("s3://#{bucket}/consolidation/sponsor/")

    run(:migrate, location)
    expect(run(:verify, location)).to start_with('OK')

    run_prefix = location.delete_prefix("s3://#{bucket}/")
    expect(objects.keys).to contain_exactly("#{run_prefix}/dump.json", "#{run_prefix}/id_map.json")
    expect(s3.api_requests.select { |request| request[:operation_name] == :put_object }
             .map { |request| request[:params][:acl] }).to all(eq('private'))

    switch_to_public
    expect(run(:verify, location)).to start_with('OK')

    in_public do
      Sponsor.unscoped.find_each do |sponsor|
        expect(sponsor.logo_url).to be_a(ActiveStorage::Attached::One).and(be_attached)
      end
      # verify replans with the same Transform the import used, so the rules
      # themselves are checked against literal outcomes rather than the plan.
      expect(SponsorLevel.unscoped.find_by(site_id: site_2023.id)[:name])
        .to eq({ 'en' => 'Supporting Partners', 'zh-TW' => '合作單位' })
    end
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/MultipleExpectations, RSpec/ExampleLength
