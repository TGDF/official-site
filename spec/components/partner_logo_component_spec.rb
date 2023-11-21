# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PartnerLogoComponent, type: :component do
  let(:partner) { create(:partner, name: '唯晶科技', url: 'https://www.winkingworks.com/zh-TW/') }

  given_a_component { described_class.new(partner:) }
  when_rendered

  it { is_expected.to have_css('img') }
  it { is_expected.to have_link }
end
