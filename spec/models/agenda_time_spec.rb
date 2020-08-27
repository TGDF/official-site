# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AgendaTime, type: :model) do
  it { is_expected.to(validate_presence_of(:label)) }
end
