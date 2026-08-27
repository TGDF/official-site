# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Speaker) do
  it { is_expected.to(validate_presence_of(:name)) }
  it { is_expected.to(validate_presence_of(:description)) }
  it { is_expected.to(validate_presence_of(:avatar)) }

  describe 'slug uniqueness' do
    let(:main) { Site.find_by(tenant_name: 'main') }

    # Each year is a tenant, so two years using the same speaker slug is normal and
    # their URLs are told apart by domain. Production already has 39 such slugs.
    it 'lets two sites use the same slug' do
      create(:speaker, slug: 'shared-slug')
      other = build(:speaker, slug: 'shared-slug', site_id: main.id + 1)

      # Without a current tenant acts_as_tenant leaves site_id alone, so a second site
      # can be expressed by the id — speakers.site_id carries no foreign key. And the
      # row is written, not merely validated: the index that was dropped lived in the
      # database, so only a write proves it is gone.
      ActsAsTenant.without_tenant { expect { other.save! }.not_to(raise_error) }
    end

    it 'refuses a duplicate slug within one site' do
      create(:speaker, slug: 'taken-slug')

      expect(build(:speaker, slug: 'taken-slug')).not_to(be_valid)
    end
  end

  # tenant_consolidation writes migrated rows with `save!(validate: false)`, which skips
  # before_validation but not before_save — and FriendlyId hooks both.
  describe 'slug generation on an unvalidated write' do
    it 'keeps the slug the record was given' do
      speaker = build(:speaker, slug: 'kept-slug')

      speaker.save!(validate: false)

      expect(speaker.reload.slug).to(eq('kept-slug'))
    end

    # A row that arrives without a slug gets one generated from its name, so the id it
    # used to be addressed by is lost. backfill_speaker_slugs fills them in first.
    it 'generates a slug for a record that has none' do
      speaker = build(:speaker, slug: nil)

      speaker.save!(validate: false)

      expect(speaker.reload.slug).to(be_present)
    end
  end
end
