# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TenantConsolidation::Plan do
  def site_with_upload(size:)
    upload = TenantConsolidation::Dump::Upload.new(
      field: 'thumbnail', url: 'https://cdn.test/a.png', path: 'uploads/a.png', size: size,
      versions: { 'thumb' => { 'url' => 'https://cdn.test/thumb_a.png', 'path' => 'uploads/thumb_a.png', 'size' => 10 },
                  'large' => { 'url' => 'https://cdn.test/large_a.png', 'path' => 'uploads/large_a.png', 'size' => 40 } }
    )
    row = TenantConsolidation::Dump::Row.new(id: 1, attributes: { 'id' => 1, 'thumbnail' => 'a.png' }, upload: upload)
    TenantConsolidation::Dump::Site.new(tenant_name: 'main', site_id: 1, models: { 'Game' => [ row ] })
  end

  it 'takes an original that is gone over from its largest version' do
    plan = described_class.carry(site_with_upload(size: 0), %w[Game])

    expect([ plan.rows.first.upload.to_h.slice(:path, :size), plan.stand_ins.map(&:version) ])
      .to eq([ { path: 'uploads/large_a.png', size: 40 }, [ 'large' ] ])
  end

  it 'leaves an original whose size could not be read missing, for the import to refuse' do
    plan = described_class.carry(site_with_upload(size: nil), %w[Game])

    expect([ plan.rows.first.upload.missing?, plan.stand_ins ]).to eq([ true, [] ])
  end
end
