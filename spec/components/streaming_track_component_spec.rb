# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StreamingTrackComponent, type: :component do
  let(:site) do
    create(
      :site
    )
  end

  given_a_component { described_class.new(track: 1, site: site) }
  when_rendered

  it { is_expected.to have_text('議程軌一') }
end
