# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PartnerGroupComponent, type: :component do
  let(:group) { create(:partner_type, name: '媒體夥伴') }

  given_a_component { described_class.new(group: group) }
  when_rendered

  it { is_expected.to have_text('媒體夥伴') }
end
