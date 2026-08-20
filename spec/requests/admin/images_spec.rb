# frozen_string_literal: true

require 'rails_helper'

# The CKEditor upload endpoint is where new /uploads/ URLs come from. It has to follow
# the same schema-based routing as the rest of the dual system, or it keeps writing
# CarrierWave files after the attachment group has moved — and every one of them is a
# reference the Phase 5 gate would then refuse to let past.
RSpec.describe('Admin::Images') do
  let(:upload) do
    Rack::Test::UploadedFile.new(Rails.root.join('spec/support/brands/logos/TGDF.png'), 'image/png')
  end

  before { sign_in(create(:admin_user)) }

  def post_upload
    post(admin_images_path, params: { upload: upload })
  end

  context 'when the attachment group is still in a tenant schema' do
    it 'stores the upload in CarrierWave' do
      post_upload

      expect(Attachment.unscoped.last.file).to(be_present)
    end

    it 'answers with the CarrierWave URL' do
      post_upload

      expect(response.parsed_body['url']).to(include('/uploads/'))
    end
  end

  context 'when the attachment group is consolidated' do
    before do
      allow(Apartment).to(receive(:excluded_models).and_return(Apartment.excluded_models + %w[Attachment]))
    end

    it 'stores the upload in ActiveStorage' do
      post_upload

      expect(Attachment.unscoped.last.file_attachment).to(be_attached)
    end

    it 'stops answering with a /uploads/ URL' do
      post_upload

      expect(response.parsed_body['url']).not_to(include('/uploads/'))
    end

    it 'still answers with the filename' do
      post_upload

      expect(response.parsed_body['filename']).to(eq('TGDF.png'))
    end
  end
end
