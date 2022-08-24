# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NavItemComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(name: 'Home', path: '/speakers') }

  before { render_inline(component) }

  it { is_expected.to have_link('Home', href: '/speakers') }
  it { is_expected.to have_text('Home') }
  it { is_expected.to have_css('.text-gray-500') }

  context 'when path is /speakers' do
    around { |example| with_request_url('/speakers') { example.run } }

    it { is_expected.to have_css('.text-red-500') }
  end
end
