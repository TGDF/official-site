# frozen_string_literal: true

require 'rails_helper'

RSpec.describe News do
  subject { build(:news) }

  it { is_expected.to belong_to(:author) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:content) }

  describe 'slug uniqueness' do
    it 'refuses a duplicate slug within one site' do
      create(:news, slug: 'taken-slug')

      expect(build(:news, slug: 'taken-slug')).not_to(be_valid)
    end
  end
end
