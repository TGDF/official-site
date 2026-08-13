# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgendaComponent, type: :component do
  let(:day) { create(:agenda_day, label: 'Day 1') }
  let(:room) { create(:room, name: 'R0') }
  let(:time) { create(:agenda_time, day:, label: 'Day 1 - 16:30 - 17:30') }
  let(:speaker) { create(:speaker, name: '廖元瑜') }
  let(:tag) { create(:agenda_tag, name: '遊戲設計') }

  before do
    agenda = create(:agenda, subject: '廟會、老街與點擊開發', language: :ZH, time:, room:)
    create(:agendas_speaker, agenda:, speaker:)
    create(:agendas_tagging, agenda:, tag:)
  end

  given_a_component { described_class.new(day:, rooms: [ room ]) }
  when_rendered(url: '/agenda')

  it { is_expected.to have_text('Day 1') }
  it { is_expected.to have_text('Day 1 - 16:30 - 17:30') }
  it { is_expected.to have_text('R0') }
  it { is_expected.to have_link('廟會、老街與點擊開發') }
  it { is_expected.to have_link('廖元瑜') }
  it { is_expected.to have_css('article > p > span', exact_text: 'ZH') }
  it { is_expected.to have_css('article > p > span', exact_text: '遊戲設計') }

  context 'when the room has no agenda' do
    given_a_component { described_class.new(day:, rooms: [ room, create(:room, name: 'R1') ]) }

    it { is_expected.to have_text('R1') }
  end

  context 'when the time slot is single track' do
    let(:time) { create(:agenda_time, day:, label: 'Day 1 - 09:15 - 09:30', single: true) }

    it { is_expected.to have_link('廟會、老街與點擊開發') }
  end
end
