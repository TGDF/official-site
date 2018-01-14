# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Agenda, type: :model do
  it { is_expected.to validate_presence_of(:subject) }
  it { is_expected.to validate_presence_of(:description) }
end
