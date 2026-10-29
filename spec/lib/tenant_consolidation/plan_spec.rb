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

  describe 'foreign keys' do
    def row(id, **attributes)
      TenantConsolidation::Dump::Row.new(id: id, attributes: { 'id' => id, **attributes }, upload: nil)
    end

    def site_with_times(*times)
      TenantConsolidation::Dump::Site.new(tenant_name: 'main', site_id: 1,
                                          models: { 'AgendaDay' => [ row(3) ], 'AgendaTime' => times })
    end

    def carry(site, **options)
      described_class.carry(site, %w[AgendaDay AgendaTime], refs: { 'AgendaTime' => { 'day_id' => 'AgendaDay' } }, **options)
    end

    it 'carries a key as the source of the row it points at, outside the attributes' do
      time = carry(site_with_times(row(7, 'day_id' => 3, 'label' => 'Morning'))).rows_of('AgendaTime').sole

      expect([ time.refs, time.attributes ]).to eq([ { 'day_id' => [ 'AgendaDay', 3 ] }, { 'label' => 'Morning' } ])
    end

    it 'carries an empty key as empty' do
      time = carry(site_with_times(row(7, 'day_id' => nil))).rows_of('AgendaTime').sole

      expect(time.refs).to eq({ 'day_id' => nil })
    end

    it 'refuses a key pointing at a row the dump does not hold' do
      expect { carry(site_with_times(row(7, 'day_id' => 9))) }
        .to raise_error(described_class::Invalid, 'main AgendaTime#7 points at AgendaDay#9, which is not in the dump')
    end

    it 'leaves such a row out, kept in skipped, when its model may skip it' do
      plan = carry(site_with_times(row(7, 'day_id' => 9), row(8, 'day_id' => 3)), skip_dangling: %w[AgendaTime])

      expect([ plan.rows_of('AgendaTime').map(&:source), plan.skipped['AgendaTime'].map(&:id) ])
        .to eq([ [ [ 'AgendaTime', 8 ] ], [ 7 ] ])
    end
  end
end
