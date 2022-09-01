# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PartnerGroupComponent, type: :component do
  subject { page }

  let(:component) { described_class.new(group: group) }
  let(:group) { create(:partner_type, name: '媒體夥伴') }

  before { render_inline(component) }

  it { is_expected.to have_text('媒體夥伴') }
end
