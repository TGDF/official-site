# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LanguageSwitchButtonComponent, type: :component do
  let(:locale) { nil }

  given_a_component { described_class.new(current_locale: locale) }
  when_rendered

  it { is_expected.to have_link('English', href: '/en') }

  context 'when locale is en' do
    let(:locale) { :en }

    it { is_expected.to have_link('繁體中文', href: '/zh-TW') }
  end
end
