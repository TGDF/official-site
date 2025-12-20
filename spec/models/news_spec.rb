# frozen_string_literal: true

require 'rails_helper'

RSpec.describe News do
  subject { build(:news) }

  it { is_expected.to belong_to(:author) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:content) }
end
