# frozen_string_literal: true

require "open-uri"

module TenantConsolidation
  # Rebuilds a dump's tenant schemas on a developer's machine, so the local run of a
  # runbook starts where production's does: preparation, backup and the census read
  # production's rows in place. Each row keeps its id, and its site_id follows its site
  # to the local Site of the same tenant name.
  #
  # Each upload's files are fetched from the url the dump recorded and written where
  # the local uploader reads them, so the local census sees the sizes production's
  # did. A file production reported gone stays gone. One whose size production could
  # not tell is left out and listed, since nothing could check what was fetched.
  #
  # A migration-only tool: it refuses outside development and test, and leaves with
  # the rest of the consolidation tooling once every group has moved.
  class Restore
    class Invalid < StandardError; end

    Result = Data.define(:rows, :files, :unchecked)

    def initialize(group, dump)
      @group = group
      @dump = dump
    end

    def run
      preflight!
      sites = @dump.sites.to_h { |dump_site| [ dump_site, local_site(dump_site.tenant_name) ] }
      site_ids = sites.to_h { |dump_site, site| [ dump_site.site_id, site.id ] }
      refuse_occupied!(sites.values)

      results = sites.map { |dump_site, site| restore_site(dump_site, site, site_ids) }
      Result.new(rows: results.sum(&:rows), files: results.sum(&:files), unchecked: results.flat_map(&:unchecked))
    end

    private

    def preflight!
      raise Invalid, "restore runs only on a developer's machine, not in #{Rails.env}" unless Rails.env.local?
      raise Invalid, "restore writes uploads to local disk; turn S3 off first" if Settings.s3.enabled
      raise Invalid, "this is a #{@dump.group} dump, not #{@group.group_name}" unless @dump.group == @group.group_name

      in_public = @group.models & Apartment.excluded_models.map(&:to_s)
      raise Invalid, "#{in_public.join(', ')} already in the public schema" if in_public.any?
    end

    def local_site(tenant_name)
      ::Site.find_by(tenant_name: tenant_name) ||
        ::Site.create!(name: tenant_name, tenant_name: tenant_name,
                       domain: "#{tenant_name.downcase.tr('_', '-')}.localhost.test")
    end

    # Rows keep their ids, so a table that already holds any would clash with them.
    def refuse_occupied!(sites)
      occupied = sites.flat_map do |site|
        Apartment::Tenant.switch(site.tenant_name) do
          @group.models.select { |name| name.constantize.unscoped.exists? }.map { |name| "#{site.tenant_name} #{name}" }
        end
      end
      raise Invalid, "already holding rows: #{occupied.join(', ')}" if occupied.any?
    end

    def restore_site(dump_site, site, site_ids)
      Apartment::Tenant.switch(site.tenant_name) do
        rows = insert_rows(dump_site, site_ids)
        files, unchecked = fetch_uploads(dump_site)
        Result.new(rows: rows, files: files, unchecked: unchecked)
      end
    end

    # Parents first, as the group lists them, so the foreign keys hold as rows land.
    def insert_rows(dump_site, site_ids)
      ActiveRecord::Base.transaction do
        @group.models.sum do |name|
          rows = dump_site.rows(name)
          next 0 if rows.empty?

          model_class = name.constantize
          model_class.unscoped.insert_all!(rows.map { |row| attributes(row, dump_site, site_ids) },
                                           record_timestamps: false)
          model_class.connection.reset_pk_sequence!(model_class.table_name)
          rows.size
        end
      end
    end

    def attributes(row, dump_site, site_ids)
      attributes = row.attributes.merge("id" => row.id)
      return attributes unless attributes.key?("site_id") && !attributes["site_id"].nil?

      local_id = site_ids.fetch(attributes["site_id"]) do
        raise Invalid, "#{dump_site.tenant_name} row ##{row.id} belongs to site #{attributes['site_id']}, " \
                       "which is not in the dump"
      end
      attributes.merge("site_id" => local_id)
    end

    def fetch_uploads(dump_site)
      files = 0
      unchecked = []
      @group.uploads.each do |name, field|
        dump_site.rows(name).each do |row|
          next unless row.upload

          uploader = name.constantize.unscoped.find(row.id).public_send(field)
          sources = [ [ uploader, row.upload.to_h.slice(:url, :size).transform_keys(&:to_s) ] ] +
                    row.upload.versions.map { |version, source| [ uploader.versions.fetch(version.to_sym), source ] }
          sources.each do |target, source|
            case source["size"]
            when nil then unchecked << "#{dump_site.tenant_name} #{name}##{row.id} #{source['url']}"
            when 0 then next
            else
              fetch(source["url"], target.path, source["size"])
              files += 1
            end
          end
        end
      end
      [ files, unchecked ]
    end

    def fetch(url, path, size)
      io = URI.open(url, "rb")
      body = io.read
      raise Invalid, "#{url} gave #{body.bytesize} bytes, production reported #{size}" unless body.bytesize == size

      FileUtils.mkdir_p(File.dirname(path))
      File.binwrite(path, body)
    ensure
      io&.close
    end
  end
end
