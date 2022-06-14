# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlockComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(block: block) }
  let(:block) { build(:text_block, content: 'Hello World') }

  let!(:rendered) { render_inline(component) }

  it { is_expected.to have_selector('.text-block') }
  it { is_expected.to have_text('Hello World') }

  context 'when component type is twitch_live' do
    let(:block) { build(:twitch_live_block, content: 'tgdf_offical') }

    it { is_expected.to have_selector('#twitch-embed') }
  end
end
