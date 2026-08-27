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

    # Rows predating acts_as_tenant have a null site_id while a new row is given one, so
    # the two sit in different scopes. The validation has to reach across that gap, or
    # consolidate[news] meets the duplicate once both carry the same site_id.
    it 'refuses a slug already held by a row that has no site' do
      build(:news, slug: 'legacy-slug').save!(validate: false)

      expect(build(:news, slug: 'legacy-slug')).not_to(be_valid)
    end
  end
end
