# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewsThumbnailComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(news: news) }
  let(:news) { create(:news, title: '報名即將開始', created_at: Time.zone.parse('2022-08-31')) }

  before { render_inline(component) }

  it { is_expected.to have_selector('img.w-full') }
  it { is_expected.to have_selector('img.max-w-full') }
  it { is_expected.to have_selector('time', text: 'Aug') }
  it { is_expected.to have_selector('time', text: '31') }

  context 'when size is small square' do
    let(:component) { described_class.new(news: news, size: :small_square) }

    it { is_expected.not_to have_selector('.datetime', text: 'Aug') }
    it { is_expected.not_to have_selector('.datetime', text: '31') }
  end
end
