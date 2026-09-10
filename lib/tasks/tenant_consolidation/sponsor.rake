# frozen_string_literal: true

# The sponsor group moves by dump → transform → import, one task per step so each
# can be run, read and repeated on its own. The runbook is docs/tenant/migrate_sponsor.md.
namespace :tenant_consolidation do
  namespace :sponsor do
    desc "Dump the sponsor group (with Partner) and report what the import will meet"
    task :backup, [ :location ] => :environment do |_t, args|
      dump = TenantConsolidation::SponsorGroup.collect
      store = TenantConsolidation::Store.open(
        args[:location].presence || TenantConsolidation::Store.new_run(TenantConsolidation::SponsorGroup::NAME)
      )
      store.write("dump.json", dump.to_json)

      puts TenantConsolidation::SponsorGroup::Census.new(dump).report
      puts ""
      puts "Dump written to #{store}"
      puts "Bring it home: aws s3 cp #{store} ./#{File.basename(store.to_s)} --recursive" if store.to_s.start_with?("s3://")
    end

    desc "Import a sponsor dump into the public schema, Partner folded in, and write its id map"
    task :migrate, [ :location ] => :environment do |_t, args|
      if args[:location].blank?
        puts "Usage: bin/rails 'tenant_consolidation:sponsor:migrate[<run location printed by backup>]'"
        exit 1
      end

      store = TenantConsolidation::Store.open(args[:location])
      dump = TenantConsolidation::Dump.parse(store.read("dump.json"))
      unless dump.group == TenantConsolidation::SponsorGroup::NAME
        puts "ERROR: #{store} holds a #{dump.group} dump, not sponsor"
        exit 1
      end

      import = TenantConsolidation::SponsorGroup::Import.new(dump)
      import.preflight!

      ids = import.import_rows!
      store.write("id_map.json", import.id_map_json(ids))
      puts import.summary
      puts "Rows imported; id map written to #{store}/id_map.json"

      import.transfer_assets!
      puts ""
      puts "Next: bin/rails 'tenant_consolidation:sponsor:verify[#{store}]'"
    end

    desc "Check the public schema row by row against a sponsor dump and the id map migrate wrote"
    task :verify, [ :location ] => :environment do |_t, args|
      if args[:location].blank?
        puts "Usage: bin/rails 'tenant_consolidation:sponsor:verify[<run location>]'"
        exit 1
      end

      store = TenantConsolidation::Store.open(args[:location])
      dump = TenantConsolidation::Dump.parse(store.read("dump.json"))
      id_map = JSON.parse(store.read("id_map.json"))
      problems = TenantConsolidation::SponsorGroup::Verify.new(dump, id_map).problems

      if problems.any?
        puts "NOT VERIFIED — #{problems.size} problem(s):"
        problems.each { |problem| puts "  - #{problem}" }
        exit 1
      end

      puts "OK: every dumped sponsor-group row is in public as planned, logos included."
    end
  end
end
