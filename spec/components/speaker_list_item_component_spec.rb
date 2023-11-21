# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpeakerListItemComponent, type: :component do
  let(:speaker) { create(:speaker, name: '詹承翰') }

  given_a_component { described_class.new(speaker:) }
  when_rendered

  it { is_expected.to have_link('詹承翰') }
  it { is_expected.to have_css('a > img') }

  context 'when speaker title given' do
    let(:speaker) { create(:speaker, name: '詹承翰', title: '唯晶科技 創辦人暨執行長') }

    it { is_expected.to have_text('唯晶科技 創辦人暨執行長') }
  end
end
