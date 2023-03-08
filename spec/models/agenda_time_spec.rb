# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(AgendaTime) do
  it { is_expected.to(validate_presence_of(:label)) }
end
