# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PassComponent, type: :component do
  let(:site) do
    create(
      :site,
      ticket_personal_price: 1000
    )
  end

  given_a_component { described_class.new(plan: :personal, site:) }
  when_rendered

  it { is_expected.to have_text('一般票') }
  it { is_expected.to have_text('NTD $1000') }

  context 'when in early bird period' do
    let(:site) do
      create(
        :site,
        ticket_personal_price: 1000,
        ticket_early_personal_price: 800,
        ticket_early_bird_due_to: Time.zone.parse('2022-08-31')
      )
    end

    before { travel_to(Time.zone.parse('2022-08-25')) }

    when_rendered

    it { is_expected.to have_text('早鳥票') }
    it { is_expected.to have_text('NTD $800') }
    it { is_expected.to have_text('早鳥票優惠至 2022年08月31日 截止') }
  end
end
