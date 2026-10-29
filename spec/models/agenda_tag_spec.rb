# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AgendaTag) do
  describe '#destroy' do
    subject(:destroy) { tag.destroy }

    let(:tag) { create(:agenda_tag) }
    let(:other_tag) { create(:agenda_tag) }
    let(:agenda) { create(:agenda) }

    before { agenda.update!(tags: [ tag, other_tag ]) }

    it { expect { destroy }.to(change(AgendasTagging, :count).by(-1)) }
    it { expect { destroy }.not_to(change { Agenda.exists?(agenda.id) }) }
    it { expect { destroy }.not_to(change { described_class.exists?(other_tag.id) }) }
  end
end
