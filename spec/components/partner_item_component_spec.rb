# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PartnerItemComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(item: item) }
  let(:item) { create(:partner, name: '唯晶科技', url: 'https://www.winkingworks.com/zh-TW/') }

  before { render_inline(component) }

  it { is_expected.to have_selector('img') }
  it { is_expected.to have_link('唯晶科技') }
end
