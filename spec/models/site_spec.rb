# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Site, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:domain) }
  it { is_expected.to validate_presence_of(:tenant_name) }

  it { is_expected.to allow_value('tgdf.tw').for(:domain) }
  it { is_expected.not_to allow_value('-other.tgdf.tw').for(:domain) }
  it { is_expected.to allow_value('tgdf_tw').for(:tenant_name) }
  it { is_expected.not_to allow_value('tgdf.tw').for(:tenant_name) }
end
