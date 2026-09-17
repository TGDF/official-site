# frozen_string_literal: true

module TenantConsolidation
  # A group's rows exactly as they stood in the tenant schemas: the file a person
  # reviews before a move, the input the import reads, and the baseline verify
  # compares the public schema against. Restoring is not its job — that is the RDS
  # snapshot's.
  #
  #   { "format": 1, "group": "sponsor", "created_at": "...",
  #     "sites": [ { "tenant_name": "tgdf", "site_id": 3,
  #                  "models": { "Sponsor": [ { "id": 5,
  #                                             "attributes": { "name": {...}, "logo": "a.png", ... },
  #                                             "upload": { "field": "logo", "url": "...",
  #                                                         "path": "uploads/...", "size": 1234,
  #                                                         "versions": { "v1": { "url": "...",
  #                                                                               "path": "...", "size": 567 } } } } ] } } ],
  #     "counts": { "tgdf": { "Sponsor": 1 } } }
  #
  # Every column is kept, nil included, so an import writes back what was there rather
  # than a column default. Times keep their microseconds — JSON's default encoding
  # stops at milliseconds, which would make every timestamp differ from its source.
  # `versions` records the files CarrierWave cut from each upload. Nothing moves them —
  # ActiveStorage makes its own variants — so they are kept only as the record of what
  # was served before the move.
  #
  # `counts` is written after the rows and checked on parse, so a dump that lost rows
  # on the way is refused instead of imported short.
  class Dump
    FORMAT = 1

    Upload = Data.define(:field, :url, :path, :size, :versions) do
      # fog reports 0 for an object that is not there, and nil when it cannot tell.
      def missing? = size.to_i.zero?
    end

    Row = Data.define(:id, :attributes, :upload)

    Site = Data.define(:tenant_name, :site_id, :models) do
      def rows(model_name) = models.fetch(model_name, [])
    end

    class Invalid < StandardError; end

    attr_reader :group, :created_at, :sites

    # Reads every Site's tenant schema. A model already served from the public schema
    # is refused: Apartment would read the public table for it, not the tenant's.
    def self.collect(group:, models:, uploads: {})
      in_public = models & Apartment.excluded_models.map(&:to_s)
      raise Invalid, "#{in_public.join(', ')} already in the public schema" if in_public.any?

      sites = ::Site.reorder(:id).map do |site|
        Apartment::Tenant.switch(site.tenant_name) do
          ActsAsTenant.with_tenant(site) do
            Site.new(
              tenant_name: site.tenant_name,
              site_id: site.id,
              models: models.to_h { |name| [ name, collect_rows(name.constantize, uploads[name]) ] }
            )
          end
        end
      end

      new(group: group, created_at: Time.current, sites: sites)
    end

    def self.collect_rows(model_class, upload_field)
      model_class.unscoped.order(:id).map do |record|
        Row.new(
          id: record.id,
          attributes: record.attribute_names.to_h { |name| [ name, encode(record[name]) ] },
          upload: upload_field && collect_upload(record, upload_field)
        )
      end
    end

    # Keyed on the stored filename rather than the uploader: CarrierWave calls a file
    # it cannot find blank, and a row whose file is gone must show up as missing
    # rather than as a row that never had one.
    def self.collect_upload(record, field)
      return if record[field].blank?

      uploader = record.public_send(field)
      Upload.new(field: field.to_s, url: uploader.url, path: uploader.path,
                 size: Assets.source_asset_size(uploader),
                 versions: uploader.versions.to_h do |name, version|
                   [ name.to_s, { "url" => version.url, "path" => version.path,
                                  "size" => Assets.source_asset_size(version) } ]
                 end)
    end

    def self.encode(value)
      case value
      when ActiveSupport::TimeWithZone, Time, DateTime then value.utc.iso8601(6)
      else value
      end
    end

    def self.parse(json)
      data = JSON.parse(json)
      raise Invalid, "unsupported dump format #{data['format'].inspect}" unless data["format"] == FORMAT

      dump = new(
        group: data.fetch("group"),
        created_at: Time.iso8601(data.fetch("created_at")),
        sites: data.fetch("sites").map { |site| parse_site(site) }
      )
      unless dump.counts == data.fetch("counts")
        raise Invalid, "row counts do not match the dump's own record — the file is incomplete"
      end

      dump
    end

    def self.parse_site(site)
      Site.new(
        tenant_name: site.fetch("tenant_name"),
        site_id: site.fetch("site_id"),
        models: site.fetch("models").transform_values do |rows|
          rows.map do |row|
            upload = row["upload"] && Upload.new(**row["upload"].symbolize_keys)
            Row.new(id: row.fetch("id"), attributes: row.fetch("attributes"), upload: upload)
          end
        end
      )
    end

    private_class_method :collect_rows, :collect_upload, :encode, :parse_site

    def initialize(group:, created_at:, sites:)
      @group = group
      @created_at = created_at
      @sites = sites
    end

    def counts
      sites.to_h { |site| [ site.tenant_name, site.models.transform_values(&:size) ] }
    end

    def to_json(*)
      JSON.pretty_generate(
        "format" => FORMAT,
        "group" => group,
        "created_at" => created_at.utc.iso8601(6),
        "sites" => sites.map { |site| site_hash(site) },
        "counts" => counts
      )
    end

    private

    def site_hash(site)
      {
        "tenant_name" => site.tenant_name,
        "site_id" => site.site_id,
        "models" => site.models.transform_values { |rows| rows.map { |row| row_hash(row) } }
      }
    end

    def row_hash(row)
      { "id" => row.id, "attributes" => row.attributes, "upload" => row.upload&.to_h&.stringify_keys }
    end
  end
end
