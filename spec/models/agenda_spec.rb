# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Agenda) do
  it { is_expected.to(validate_presence_of(:subject)) }
  it { is_expected.to(validate_presence_of(:description)) }

  describe '#destroy' do
    subject(:destroy) { agenda.destroy }

    let(:agenda) { create(:agenda) }
    let(:tag) { create(:agenda_tag) }

    before { agenda.update!(tags: [tag]) }

    it { is_expected.to(be_truthy) }
    it { expect { destroy }.not_to(change { tag.reload.present? }) }
    it { expect { destroy }.to(change(AgendasTagging, :count).by(-1)) }
  end
end
