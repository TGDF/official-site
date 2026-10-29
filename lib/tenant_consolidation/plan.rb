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
  # own variants from whatever original it is given. With no version left either, or
  # with an original whose size could not be read, the upload stays missing and the
  # import refuses it.
  class Plan
    Row = Data.define(:source, :model, :attributes, :refs, :upload)
    StandIn = Data.define(:source, :field, :version, :missing_path, :path)

    class Invalid < StandardError; end

    # Never carried over: the public row gets a fresh id and the importing site's id.
    DROPPED = %w[id site_id].freeze

    # Rows of a model a group lists in SHARED are one row across sites when every
    # other column matches; the timestamps kept are the first site's.
    SHARED_IGNORED = %w[created_at updated_at].freeze

    def self.shared_key(row) = [ row.model, row.attributes.except(*SHARED_IGNORED) ]

    def self.shared_keys(plans, model)
      plans.flat_map { |plan| plan.rows_of(model) }.map { |row| shared_key(row) }.uniq
    end

    attr_reader :site, :rows, :skipped, :stand_ins

    # A group whose rows move as they are, each to the model it was dumped from.
    # `refs` names each foreign key a model carries and the model it points at, as
    # { "AgendaTime" => { "day_id" => "AgendaDay" } }; `models` lists parents first. A
    # key pointing at a row the dump does not hold refuses the plan, unless its model
    # is in `skip_dangling` — then the row is left out and kept in `skipped`.
    def self.carry(site, models, refs: {}, skip_dangling: [])
      skipped = Hash.new { |hash, model| hash[model] = [] }
      rows = models.flat_map do |model|
        keys = refs.fetch(model, {})
        site.rows(model).filter_map do |row|
          dangling = keys.find { |column, parent| dangling?(site, row, column, parent) }
          if dangling && skip_dangling.include?(model)
            skipped[model] << row
            next
          end
          if dangling
            raise Invalid, "#{site.tenant_name} #{model}##{row.id} points at #{dangling.last}" \
                           "##{row.attributes[dangling.first]}, which is not in the dump"
          end

          Row.new([ model, row.id ], model, row.attributes.except(*DROPPED, *keys.keys),
                  keys.to_h { |column, parent| [ column, row.attributes[column] && [ parent, row.attributes[column] ] ] },
                  row.upload)
        end
      end
      new(site, rows: rows, skipped: skipped.to_h)
    end

    def self.dangling?(site, row, column, parent)
      id = row.attributes[column]
      id && site.rows(parent).none? { |candidate| candidate.id == id }
    end
    private_class_method :dangling?

    def initialize(site, rows:, skipped: {})
      @site = site
      @skipped = skipped
      @stand_ins = []
      @rows = rows.map { |row| with_stand_in(row) }
    end

    def rows_of(model) = rows.select { |row| row.model == model }

    private

    def with_stand_in(row)
      return row unless row.upload&.gone?

      name, version = row.upload.versions.reject { |_name, file| file["size"].to_i.zero? }
                         .max_by { |_name, file| file["size"] }
      return row unless name

      @stand_ins << StandIn.new(row.source, row.upload.field, name, row.upload.path, version["path"])
      row.with(upload: row.upload.with(url: version["url"], path: version["path"], size: version["size"]))
    end
  end
end
