# frozen_string_literal: true

require 'rails_helper'

Rails.application.load_tasks unless Rake::Task.task_defined?('tenant_consolidation:game:migrate')

# How game:migrate moves a thumbnail into ActiveStorage, and what a failed transfer
# leaves behind. Assets move after the rows commit, so their transaction does not stay
# open across every download in the group; a failed run leaves the rows in public,
# and recovery is rollback[game] and a fresh run.
#
# rubocop:disable RSpec/DescribeClass
RSpec.describe 'tenant_consolidation:game:migrate' do
  include_context 'with consolidation tenants'

  let(:location) { Rails.root.join('tmp/consolidation/spec', SecureRandom.hex(4)).to_s }

  before do
    # Name only in :en — under the default locale (zh-TW) the Game is invalid.
    seed_game(main_site, name: { 'en' => 'WithThumbnail' }, with_thumbnail: true)
    silently { run_task('tenant_consolidation:game:backup', location) }
  end

  after { FileUtils.rm_rf(location) }

  def migrate
    silently { run_task('tenant_consolidation:game:migrate', location) }
  end

  def stored_files
    Dir.glob(File.join(ActiveStorage::Blob.service.root, '**', '*')).select { |path| File.file?(path) }
  end

  def public_thumbnail
    in_public { Game.unscoped.find_by(site_id: main_site.id).thumbnail_attachment }
  end

  # ActiveStorage#attach auto-saves only a valid record; a legacy row predating a
  # tightened rule must still get its attachment rather than silently lose it.
  it 'attaches the thumbnail at the source size, even to a record invalid under current validations' do
    allow(URI).to receive(:open) { File.open(test_png, 'rb') }
    migrate

    expect([ public_thumbnail.attached?, public_thumbnail.byte_size ]).to eq([ true, File.size(test_png) ])
  end

  # A CDN can answer a missing object with 200 and an HTML error page: non-empty, so
  # only the comparison with the source size read from storage tells it apart.
  context 'when the downloaded body differs from the source size' do
    before { allow(URI).to receive(:open) { StringIO.new('<html>Not Found</html>') } }

    it 'aborts the run' do
      expect { migrate }.to raise_error(RuntimeError, /Asset size mismatch/)
    end

    it 'leaves the thumbnail unattached and no file of the rejected body in storage' do
      before = stored_files
      suppress(RuntimeError) { migrate }

      expect([ public_thumbnail.attached?, stored_files - before ]).to eq([ false, [] ])
    end
  end

  context 'when a step after the upload fails' do
    before do
      allow(URI).to receive(:open) { File.open(test_png, 'rb') }
      allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_wrap_original do |original, **options|
        original.call(**options).tap { |blob| allow(blob).to receive(:analyze).and_raise('analysis failed') }
      end
    end

    it 'leaves no file of the uploaded blob in storage' do
      before = stored_files
      suppress(RuntimeError) { migrate }

      expect(stored_files - before).to be_empty
    end
  end

  context 'when a download fails' do
    before { allow(URI).to receive(:open).and_raise(Errno::ECONNREFUSED) }

    it 'aborts the run' do
      expect { migrate }.to raise_error(Errno::ECONNREFUSED)
    end

    it 'leaves the rows committed and the thumbnail unattached' do
      suppress(Errno::ECONNREFUSED) { migrate }

      expect([ public_count(Game), public_thumbnail.attached? ]).to eq([ 1, false ])
    end
  end
end
# rubocop:enable RSpec/DescribeClass
