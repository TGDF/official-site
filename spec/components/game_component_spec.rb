# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GameComponent, type: :component do
  let(:game) { create(:game, name: '遠古神話', description: '範例遊戲', team: '玄武工作室') }

  given_a_component { described_class.new(game:) }
  when_rendered

  it { is_expected.to have_css('.indie-game__name', text: '遠古神話') }
  it { is_expected.to have_css('.indie-game__description', text: '範例遊戲') }
  it { is_expected.to have_css('.indie-game__team', text: '玄武工作室') }
end
