# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewsListItemComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(news: news) }
  let(:news) { create(:news, title: '報名即將開始') }

  before { render_inline(component) }

  it { is_expected.to have_link('報名即將開始') }
  it { is_expected.to have_link('了解更多') }
end
