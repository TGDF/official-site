# frozen_string_literal: true

# The groups that move by dump → transform → import, one task per step so each can
# be run, read and repeated on its own. Each is TenantConsolidation::<Name>Group,
# resolved when a task runs (tasks load before the application autoloads), and has
# its runbook at docs/tenant/migrate_<name>.md.
namespace :tenant_consolidation do
  DUMP_GROUPS = %w[sponsor game].freeze

  def dump_group(name) = TenantConsolidation.const_get("#{name.camelize}Group")

  DUMP_GROUPS.each do |name|
    namespace name do
      desc "Dump the #{name} group and report what the import will meet"
      task :backup, [ :location ] => :environment do |_t, args|
        group = dump_group(name)
        dump = TenantConsolidation::Dump.collect(group: name, models: group::MODELS, uploads: group::UPLOADS)
        store = TenantConsolidation::Store.open(args[:location].presence || TenantConsolidation::Store.new_run(name))
        store.write("dump.json", dump.to_json)

        puts TenantConsolidation::Census.new(group, dump).report
        puts ""
        puts "Dump written to #{store}"
        puts "Bring it home: aws s3 cp #{store} ./#{File.basename(store.to_s)} --recursive" if store.to_s.start_with?("s3://")
      end

      desc "Import a #{name} dump into the public schema and write its id map"
      task :migrate, [ :location ] => :environment do |_t, args|
        if args[:location].blank?
          puts "Usage: bin/rails 'tenant_consolidation:#{name}:migrate[<run location printed by backup>]'"
          exit 1
        end

        store = TenantConsolidation::Store.open(args[:location])
        dump = TenantConsolidation::Dump.parse(store.read("dump.json"))
        unless dump.group == name
          puts "ERROR: #{store} holds a #{dump.group} dump, not #{name}"
          exit 1
        end

        import = TenantConsolidation::Import.new(dump_group(name), dump)
        import.preflight!

        ids = import.import_rows!
        store.write("id_map.json", import.id_map_json(ids))
        puts import.summary
        puts "Rows imported; id map written to #{store}/id_map.json"

        import.transfer_assets!
        puts ""
        puts "Next: bin/rails 'tenant_consolidation:#{name}:verify[#{store}]'"
      end

      desc "Check the public schema row by row against a #{name} dump and the id map migrate wrote"
      task :verify, [ :location ] => :environment do |_t, args|
        if args[:location].blank?
          puts "Usage: bin/rails 'tenant_consolidation:#{name}:verify[<run location>]'"
          exit 1
        end

        store = TenantConsolidation::Store.open(args[:location])
        dump = TenantConsolidation::Dump.parse(store.read("dump.json"))
        id_map = JSON.parse(store.read("id_map.json"))
        problems = TenantConsolidation::Verify.new(dump_group(name), dump, id_map).problems

        if problems.any?
          puts "NOT VERIFIED — #{problems.size} problem(s):"
          problems.each { |problem| puts "  - #{problem}" }
          exit 1
        end

        puts "OK: every dumped #{name}-group row is in public as planned, uploads included."
      end
    end
  end
end
