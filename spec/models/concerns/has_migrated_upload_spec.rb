# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HasMigratedUpload do
  # Use Speaker as the test subject since it has the concern
  let(:speaker) { create(:speaker) }
  let(:test_file) { Rails.root.join('spec/support/brands/logos/TGDF.png') }

  before do
    # Ensure flags are disabled by default
    Flipper.disable(:active_storage_read)
    Flipper.disable(:active_storage_write)
  end

  describe '#avatar_url' do
    context 'when both flags are disabled' do
      it 'returns CarrierWave URL' do
        expect(speaker.avatar_url).to include('uploads/')
      end

      it 'returns CarrierWave version URL' do
        expect(speaker.avatar_url(:v1)).to include('uploads/')
      end
    end

    context 'when active_storage_read is enabled with attachment' do
      before do
        Flipper.enable(:active_storage_read)
        speaker.avatar_attachment.attach(
          io: File.open(test_file),
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end

      it 'returns ActiveStorage attachment' do
        result = speaker.avatar_url
        expect(result).to be_a(ActiveStorage::Attached::One)
      end

      it 'returns variant for version' do
        result = speaker.avatar_url(:v1)
        expect(result).to be_a(ActiveStorage::VariantWithRecord)
      end
    end

    context 'when active_storage_read is enabled without attachment' do
      before { Flipper.enable(:active_storage_read) }

      it 'falls back to CarrierWave URL' do
        expect(speaker.avatar_url).to include('uploads/')
      end
    end

    context 'when active_storage_write is enabled with attachment' do
      before do
        Flipper.enable(:active_storage_write)
        speaker.avatar_attachment.attach(
          io: File.open(test_file),
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end

      it 'returns ActiveStorage attachment (serves what was written)' do
        result = speaker.avatar_url
        expect(result).to be_a(ActiveStorage::Attached::One)
      end
    end

    context 'when active_storage_write is enabled without attachment' do
      before { Flipper.enable(:active_storage_write) }

      it 'falls back to CarrierWave URL' do
        expect(speaker.avatar_url).to include('uploads/')
      end
    end
  end

  describe '#avatar_present?' do
    context 'with CarrierWave file only' do
      it 'returns true' do
        expect(speaker.avatar_present?).to be true
      end
    end

    context 'with ActiveStorage attachment only' do
      let(:speaker) { create(:speaker, :without_avatar) }

      before do
        speaker.avatar_attachment.attach(
          io: File.open(test_file),
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end

      it 'returns true' do
        expect(speaker.avatar_present?).to be true
      end
    end

    context 'with neither file' do
      let(:speaker) { create(:speaker, :without_avatar) }

      it 'returns false' do
        expect(speaker.avatar_present?).to be false
      end
    end

    context 'with both files' do
      before do
        speaker.avatar_attachment.attach(
          io: File.open(test_file),
          filename: 'avatar.png',
          content_type: 'image/png'
        )
      end

      it 'returns true' do
        expect(speaker.avatar_present?).to be true
      end
    end
  end
end
