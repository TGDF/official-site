# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgendaComponent, type: :component do
  let(:day) { create(:agenda_day, label: 'Day 1') }

  given_a_component { described_class.new(day:, rooms: []) }
  when_rendered(url: '/agenda')

  it { is_expected.to have_text('Day 1') }
end
