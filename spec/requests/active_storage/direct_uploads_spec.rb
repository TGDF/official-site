# frozen_string_literal: true

require 'rails_helper'

# Every upload on this site goes through the server, so Active Storage's direct-upload
# endpoint has no caller. Left open, it lets any visitor create a blob and receive its
# signed id, which a variation key copied from any public image turns into a request
# that makes the server process attacker-chosen content.
RSpec.describe('ActiveStorage direct uploads') do
  let(:blob_params) do
    { blob: { filename: 'avatar.png', byte_size: 6120, checksum: 'aGVsbG8=', content_type: 'image/png' } }
  end

  it 'answers not found' do
    post('/rails/active_storage/direct_uploads', params: blob_params, as: :json)

    expect(response).to(have_http_status(:not_found))
  end

  it 'creates no blob' do
    expect { post('/rails/active_storage/direct_uploads', params: blob_params, as: :json) }
      .not_to(change(ActiveStorage::Blob, :count))
  end
end
