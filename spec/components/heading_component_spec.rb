# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HeadingComponent, type: :component do
  given_a_component(text: 'About Taipei Game Developer Forum')
  when_rendered

  it { is_expected.to have_css('.font-semibold') }
end
