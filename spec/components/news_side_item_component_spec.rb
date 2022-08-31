# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewsSideItemComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(news: news) }
  let(:news) { create(:news, title: '報名即將開始', created_at: Time.zone.parse('2022-08-31')) }

  before { render_inline(component) }

  it { is_expected.to have_link('報名即將開始') }
  it { is_expected.to have_selector('time', text: '08月31日 00:00') }
end
