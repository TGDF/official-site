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
  class Plan
    Row = Data.define(:source, :model, :attributes, :refs, :upload)

    class Invalid < StandardError; end

    # Never carried over: the public row gets a fresh id and the importing site's id.
    DROPPED = %w[id site_id].freeze

    attr_reader :site, :rows, :skipped

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
      @rows = rows
      @skipped = skipped
    end

    def rows_of(model) = rows.select { |row| row.model == model }
  end
end
