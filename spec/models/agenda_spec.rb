# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Agenda) do
  it { is_expected.to(validate_presence_of(:subject)) }
  it { is_expected.to(validate_presence_of(:description)) }

  describe '#translated?' do
    subject { agenda.translated? }

    context 'when the translated language differs from the original language' do
      let(:agenda) { build(:agenda, language: 'ZH', translated_language: 'EN') }

      it { is_expected.to(be(true)) }
    end

    context 'when the translated language matches the original language' do
      let(:agenda) { build(:agenda, language: 'ZH', translated_language: 'ZH') }

      it { is_expected.to(be(false)) }
    end

    context 'when no translated language is set' do
      let(:agenda) { build(:agenda, language: 'ZH', translated_language: nil) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#begin_at=' do
    subject { build(:agenda, begin_at: value).begin_at }

    context 'when the value carries a date prefix' do
      let(:value) { '2026-07-16 16:30' }

      it { is_expected.to(eq('16:30')) }
    end

    context 'when the value is a full ISO datetime' do
      let(:value) { '2026-07-16T16:30:00' }

      it { is_expected.to(eq('16:30')) }
    end

    context 'when the value is already a clock time' do
      let(:value) { '16:30' }

      it { is_expected.to(eq('16:30')) }
    end

    context 'when the value is blank' do
      let(:value) { '' }

      it { is_expected.to(be_nil) }
    end

    context 'when the value holds no clock time' do
      let(:value) { '下午三點半' }

      it { is_expected.to(eq('下午三點半')) }
    end
  end

  describe '#end_at=' do
    subject { build(:agenda, end_at: '2026-07-16 17:00').end_at }

    it { is_expected.to(eq('17:00')) }
  end

  describe '#destroy' do
    subject(:destroy) { agenda.destroy }

    let(:agenda) { create(:agenda) }
    let(:tag) { create(:agenda_tag) }

    before { agenda.update!(tags: [ tag ]) }

    it { is_expected.to(be_truthy) }
    it { expect { destroy }.not_to(change { tag.reload.present? }) }
    it { expect { destroy }.to(change(AgendasTagging, :count).by(-1)) }
  end
end
