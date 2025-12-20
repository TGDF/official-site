# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HasMigratedUpload do
  let(:test_file) { Rails.root.join('spec/support/brands/logos/TGDF.png') }

  describe 'schema-based routing' do
    context 'with tenant-schema models' do
      let(:speaker) { create(:speaker) }

      it 'always returns CarrierWave URL' do
        expect(speaker.avatar_url).to include('uploads/')
      end

      it 'returns CarrierWave URL even with ActiveStorage attached' do
        speaker.avatar_attachment.attach(io: File.open(test_file), filename: 'avatar.png')
        expect(speaker.avatar_url).to include('uploads/')
      end
    end

    context 'with public-schema models' do
      let(:site) { Site.first || create(:site) }

      it 'returns ActiveStorage when attached' do
        site.logo_attachment.attach(io: File.open(test_file), filename: 'logo.png')
        expect(site.logo_url).to be_a(ActiveStorage::Attached::One)
      end

      it 'falls back to CarrierWave when not attached' do
        site.logo_attachment.purge if site.logo_attachment.attached?
        expect(site.logo_url).to be_present
      end
    end
  end

  describe '#field_present?' do
    let(:speaker) { create(:speaker) }

    it 'returns true with CarrierWave file' do
      expect(speaker.avatar_present?).to be true
    end

    it 'returns true with ActiveStorage attachment' do
      speaker = create(:speaker, :without_avatar)
      speaker.avatar_attachment.attach(io: File.open(test_file), filename: 'avatar.png')
      expect(speaker.avatar_present?).to be true
    end

    it 'returns false without any file' do
      speaker = create(:speaker, :without_avatar)
      expect(speaker.avatar_present?).to be false
    end
  end
end
