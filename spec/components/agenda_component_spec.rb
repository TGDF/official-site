# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgendaComponent, type: :component do
  let(:day) { create(:agenda_day, label: 'Day 1') }
  let(:room) { create(:room, name: 'R0') }
  let(:time) { create(:agenda_time, day:, label: 'Day 1 - 16:30 - 17:30') }
  let(:session) do
    { subject: '廟會、老街與點擊開發', speaker: '廖元瑜',
      begin_at: '2026-07-16 16:30', end_at: '17:00' }
  end
  let(:sessions) { [ session ] }

  before do
    sessions.each_with_index do |attributes, order|
      agenda = create(:agenda, subject: attributes[:subject], language: :ZH, order:,
                               time:, room:, begin_at: attributes[:begin_at], end_at: attributes[:end_at])
      if attributes[:speaker].present?
        create(:agendas_speaker, agenda:, speaker: create(:speaker, name: attributes[:speaker]))
      end
      create(:agendas_tagging, agenda:, tag: create(:agenda_tag, name: '遊戲設計'))
    end
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
  it { is_expected.to have_css('article > p', exact_text: '16:30 - 17:00') }

  context 'when the session time carries no date prefix' do
    let(:session) { super().merge(begin_at: '16:30') }

    it { is_expected.to have_css('article > p', exact_text: '16:30 - 17:00') }
  end

  context 'when the session has no time of its own' do
    let(:session) { super().merge(begin_at: nil, end_at: nil) }

    it { is_expected.to have_link('廟會、老街與點擊開發') }
    it { is_expected.to have_no_text('16:30 - 17:00') }
  end

  context 'when the session has no speaker yet' do
    let(:session) { super().merge(speaker: nil) }

    it { is_expected.to have_text('廟會、老街與點擊開發') }
    it { is_expected.to have_no_link('廟會、老街與點擊開發') }
  end

  context 'when two sessions share a slot in the same room' do
    let(:sessions) do
      [ session,
        session.merge(subject: '八點檔 IP 的遊戲化路徑', speaker: 'Ray Hung',
                      begin_at: '2026-07-16 17:00', end_at: '17:30') ]
    end

    it { is_expected.to have_text(/16:30 - 17:00.*17:00 - 17:30/m) }
  end

  context 'when the room has no agenda' do
    given_a_component { described_class.new(day:, rooms: [ room, create(:room, name: 'R1') ]) }

    it { is_expected.to have_text('R1') }
  end

  context 'when the time slot is single track' do
    let(:time) { create(:agenda_time, day:, label: 'Day 1 - 09:15 - 09:30', single: true) }

    it { is_expected.to have_link('廟會、老街與點擊開發') }
  end
end
