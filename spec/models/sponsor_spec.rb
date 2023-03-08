# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Sponsor) do
  it { is_expected.to(belong_to(:level)) }
  it { is_expected.to(validate_presence_of(:name)) }
  it { is_expected.to(validate_presence_of(:logo)) }
end
