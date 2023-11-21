# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProposalFormComponent, type: :component do
  given_a_component(src: 'https://form.jotform.me/91287937269474')
  when_rendered

  it { is_expected.to have_css('#proposal iframe') }

  context 'when description is given' do
    let(:component) { described_class.new(src: 'https://form.jotform.me/91287937269474', description: 'Hello World') }

    it { is_expected.to have_text('Hello World') }
  end
end
