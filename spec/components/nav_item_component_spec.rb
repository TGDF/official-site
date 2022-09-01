# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NavItemComponent, type: :component do
  given_a_component(name: 'Home', path: '/speakers')
  when_rendered

  it { is_expected.to have_link('Home', href: '/speakers') }
  it { is_expected.to have_text('Home') }
  it { is_expected.to have_css('.text-gray-500') }

  context 'when path is /speakers' do
    when_rendered(url: '/speakers')

    it { is_expected.to have_css('.text-red-500') }
  end

  context 'when target is configured' do
    let(:component) { described_class.new(name: 'Home', path: '/', target: '_blank') }

    it { is_expected.to have_css('[target=_blank]') }
  end

  context 'when display as button' do
    let(:component) { described_class.new(name: 'Home', path: '/', button: true) }

    it { is_expected.to have_css('.text-white') }
    it { is_expected.to have_css('.bg-red-500') }
    it { is_expected.to have_css('.rounded') }
  end
end
