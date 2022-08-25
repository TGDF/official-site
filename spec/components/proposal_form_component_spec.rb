# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProposalFormComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(src: 'https://form.jotform.me/91287937269474') }

  before { render_inline(component) }

  it { is_expected.to have_selector('#proposal iframe') }

  context 'when description is given' do
    let(:component) { described_class.new(src: 'https://form.jotform.me/91287937269474', description: 'Hello World') }

    it { is_expected.to have_text('Hello World') }
  end
end
