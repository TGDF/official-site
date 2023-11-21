# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BlockComponent, type: :component do
  let(:block) { build(:text_block, content: 'Hello World') }

  given_a_component { described_class.new(block:) }
  when_rendered

  it { is_expected.to have_css('.text-block') }
  it { is_expected.to have_text('Hello World') }

  context 'when component type is twitch_live' do
    let(:block) { build(:twitch_live_block, content: 'tgdf_offical') }

    it { is_expected.to have_css('#twitch-embed') }
  end
end
