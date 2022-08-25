# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeadingComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(text: 'About Taipei Game Developer Forum') }

  before { render_inline(component) }

  it { is_expected.to have_css('.font-semibold') }
end
