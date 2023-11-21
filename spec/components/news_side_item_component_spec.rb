# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewsSideItemComponent, type: :component do
  let(:news) { create(:news, title: '報名即將開始', created_at: Time.zone.parse('2022-08-31')) }

  given_a_component { described_class.new(news:) }
  when_rendered

  it { is_expected.to have_link('報名即將開始') }
  it { is_expected.to have_css('time', text: '08月31日 00:00') }
end
