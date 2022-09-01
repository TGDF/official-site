# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewsListItemComponent, type: :component do
  let(:news) { create(:news, title: '報名即將開始') }

  given_a_component { described_class.new(news: news) }
  when_rendered

  it { is_expected.to have_link('報名即將開始') }
  it { is_expected.to have_link('了解更多') }
end
