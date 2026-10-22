# frozen_string_literal: true

module TenantConsolidation
  # What a group's dump holds and what the import will meet, read before anything is
  # written: the rows per site, the files that cannot be fetched, the versions standing
  # in for a lost original, the attachments left where none should be, and whatever
  # the group's own rules will do on import.
  class Census
    Missing = Data.define(:tenant_name, :model, :id, :path)

    def initialize(group, dump)
      @group = group
      @dump = dump
    end

    def missing_sources
      plans.flat_map do |plan|
        plan.rows.select { |row| row.upload&.missing? }
            .map { |row| Missing.new(plan.site.tenant_name, *row.source, row.upload.path) }
      end
    end

    def stand_ins
      plans.flat_map { |plan| plan.stand_ins.map { |stand_in| [ plan.site.tenant_name, stand_in ] } }
    end

    # A consolidated model is the only one that may carry an ActiveStorage
    # attachment; one on a tenant-schema row was left by tooling or an aborted run,
    # and would sit on a public row with the same id once the group has moved.
    def leftover_attachments
      ActiveStorage::Attachment.where(record_type: @group::UPLOADS.keys).group(:record_type).count
    end

    def report
      [
        counts_table,
        section("Uploads whose source file is missing", missing_sources) do |m|
          "#{m.tenant_name} #{m.model}##{m.id} #{m.path}"
        end,
        section("Uploads taken over from their largest version, the original being gone", stand_ins) do |tenant_name, s|
          "#{tenant_name} #{s.source.join('#')} #{s.field} ← #{s.version} #{s.path}"
        end,
        section("Leftover ActiveStorage attachments on #{@group::UPLOADS.keys.join('/')}",
                leftover_attachments.to_a) { |type, count| "#{type}: #{count}" },
        *group_sections
      ].join("\n\n")
    end

    private

    def plans
      @plans ||= @dump.sites.map { |site| @group.plan(site) }
    end

    def group_sections
      return [] unless @group.respond_to?(:census_sections)

      @group.census_sections(@dump).map { |title, lines| section(title, lines, &:itself) }
    end

    def counts_table
      models = @group::MODELS
      width = [ @dump.sites.map { |site| site.tenant_name.size }.max.to_i, 6 ].max
      header = "site".ljust(width) + models.map { |m| m.rjust(14) }.join
      rows = @dump.counts.map do |tenant_name, counts|
        tenant_name.ljust(width) + models.map { |m| counts.fetch(m, 0).to_s.rjust(14) }.join
      end
      [ "#{@group::NAME.humanize} group — #{@dump.sites.size} site(s)", header, *rows ].join("\n")
    end

    def section(title, items, &line)
      [ "#{title} (#{items.size})", *items.map { |item| "  #{line.call(item)}" } ].join("\n")
    end
  end
end
