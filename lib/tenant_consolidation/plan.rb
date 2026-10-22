# frozen_string_literal: true

module TenantConsolidation
  # What one dumped site becomes in the public schema. A group turns each dumped site
  # into a plan; the census prints it, the import writes exactly it, and verify
  # compares the public schema against it — so the plan reads the dump and nothing else.
  #
  #   Row  source      the dumped row it comes from, as [model, id]
  #        model       the public model it is written as
  #        attributes  its columns, without id, site_id or any foreign key
  #        refs        each foreign key, as the source of the parent it points at
  #        upload      the dumped upload ActiveStorage takes over, if any
  #
  # Rows are in write order: a parent before any row whose refs name it. `skipped`
  # holds the dumped rows the plan does not carry, by model, so they stay reviewable.
  #
  # An upload whose original is gone is taken over from the largest version
  # CarrierWave cut from it, and recorded in `stand_ins`; ActiveStorage derives its
  # own variants from whatever original it is given. With no version left either,
  # the upload stays missing and the import refuses it.
  class Plan
    Row = Data.define(:source, :model, :attributes, :refs, :upload)
    StandIn = Data.define(:source, :field, :version, :missing_path, :path)

    class Invalid < StandardError; end

    # Never carried over: the public row gets a fresh id and the importing site's id.
    DROPPED = %w[id site_id].freeze

    attr_reader :site, :rows, :skipped, :stand_ins

    # A group whose rows move as they are, each to the model it was dumped from.
    def self.carry(site, models)
      rows = models.flat_map do |model|
        site.rows(model).map do |row|
          Row.new([ model, row.id ], model, row.attributes.except(*DROPPED), {}, row.upload)
        end
      end
      new(site, rows: rows)
    end

    def initialize(site, rows:, skipped: {})
      @site = site
      @skipped = skipped
      @stand_ins = []
      @rows = rows.map { |row| with_stand_in(row) }
    end

    def rows_of(model) = rows.select { |row| row.model == model }

    private

    def with_stand_in(row)
      return row unless row.upload&.missing?

      name, version = row.upload.versions.reject { |_name, file| file["size"].to_i.zero? }
                         .max_by { |_name, file| file["size"] }
      return row unless name

      @stand_ins << StandIn.new(row.source, row.upload.field, name, row.upload.path, version["path"])
      row.with(upload: row.upload.with(url: version["url"], path: version["path"], size: version["size"]))
    end
  end
end
