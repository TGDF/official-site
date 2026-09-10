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
  end
end
