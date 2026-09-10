# frozen_string_literal: true

require 'rails_helper'
require 'aws-sdk-s3'

RSpec.describe TenantConsolidation::Store do
  let(:bucket) { 'files.example.test' }

  before do
    allow(Settings.s3).to receive_messages(bucket: bucket, enabled: true)
  end

  describe '.new_run' do
    let(:at) { Time.utc(2026, 9, 10, 12, 30, 5) }

    it 'places the run under consolidation/ in the application bucket' do
      expect(described_class.new_run('sponsor', at: at))
        .to eq('s3://files.example.test/consolidation/sponsor/20260910T123005Z')
    end

    it 'falls back to tmp/ when files are not stored on S3' do
      allow(Settings.s3).to receive(:enabled).and_return(false)

      expect(described_class.new_run('sponsor', at: at))
        .to eq(Rails.root.join('tmp/consolidation/sponsor/20260910T123005Z').to_s)
    end
  end

  describe 'a local run' do
    let(:dir) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)) }
    let(:store) { described_class.open(dir.to_s) }

    after { FileUtils.rm_rf(dir) }

    it 'reads back what it wrote' do
      store.write('dump.json', '{"a":1}')

      expect(store.read('dump.json')).to eq('{"a":1}')
    end
  end

  describe 'an S3 run' do
    let(:client) { Aws::S3::Client.new(stub_responses: true) }
    let(:store) { described_class.open("s3://#{bucket}/consolidation/sponsor/run", s3_client: client) }

    it 'writes a private object under the run prefix' do
      store.write('dump.json', '{}')

      expect(client.api_requests.sole).to include(
        operation_name: :put_object,
        params: include(bucket: bucket, key: 'consolidation/sponsor/run/dump.json', acl: 'private')
      )
    end

    it 'reads a file from under the run prefix' do
      client.stub_responses(:get_object, lambda { |context|
        { body: context.params[:key] == 'consolidation/sponsor/run/dump.json' ? '{"a":1}' : 'wrong key' }
      })

      expect(store.read('dump.json')).to eq('{"a":1}')
    end

    it 'refuses a location outside consolidation/' do
      expect { described_class.open("s3://#{bucket}/uploads/sponsor", s3_client: client) }
        .to raise_error(described_class::Invalid, %r{outside consolidation/})
    end

    it 'refuses a bucket that is not the application bucket' do
      expect { described_class.open('s3://someone-else/consolidation/sponsor', s3_client: client) }
        .to raise_error(described_class::Invalid, /not in the application's bucket/)
    end
  end
end
