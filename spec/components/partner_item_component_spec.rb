# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PartnerItemComponent, type: :component do
  let(:item) { create(:partner, name: '唯晶科技', url: 'https://www.winkingworks.com/zh-TW/') }

  given_a_component { described_class.new(item: item) }
  when_rendered

  it { is_expected.to have_selector('img') }
  it { is_expected.to have_link('唯晶科技') }
end
