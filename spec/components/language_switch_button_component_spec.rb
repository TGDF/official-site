# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LanguageSwitchButtonComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(current_locale: locale) }
  let(:locale) { nil }

  before do
    with_request_url('/') do
      render_inline(component)
    end
  end

  it { is_expected.to have_link('English', href: '/en') }

  context 'when locale is en' do
    let(:locale) { :en }

    it { is_expected.to have_link('繁體中文', href: '/zh-TW') }
  end
end
