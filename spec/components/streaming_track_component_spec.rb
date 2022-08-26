# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StreamingTrackComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(track: 1, site: site) }
  let(:site) do
    create(
      :site
    )
  end

  before do
    with_request_url('/') { render_inline(component) }
  end

  it { is_expected.to have_text('議程軌一') }
end
