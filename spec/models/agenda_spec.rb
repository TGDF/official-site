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
