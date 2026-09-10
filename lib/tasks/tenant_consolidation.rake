# frozen_string_literal: true

namespace :tenant_consolidation do
  # Model configurations for tenant consolidation and storage migration
  # Models in tenant schema need consolidation first, then storage migration happens automatically
  # Models already in public schema (Site) only need storage migration
  MODEL_CONFIGS = [
    { model: "Site", field: :logo, attachment: :logo_attachment },
    { model: "Site", field: :figure, attachment: :figure_attachment },
    { model: "Slider", field: :image, attachment: :image_attachment },
    { model: "Partner", field: :logo, attachment: :logo_attachment },
    { model: "Sponsor", field: :logo, attachment: :logo_attachment },
    { model: "Speaker", field: :avatar, attachment: :avatar_attachment },
    { model: "Attachment", field: :file, attachment: :file_attachment },
    { model: "Game", field: :thumbnail, attachment: :thumbnail_attachment },
    { model: "News", field: :thumbnail, attachment: :thumbnail_attachment }
  ].freeze

  # Models that need tenant consolidation (not Site, which is already in public)
  CONSOLIDATION_MODELS = MODEL_CONFIGS.reject { |c| c[:model] == "Site" }.uniq { |c| c[:model] }

  # Every field that may contain a /uploads/ URL — CKEditor rich-text bodies plus the
  # URL fields an admin can point at an uploaded asset. The Phase 5 S3-deletion gate
  # scans ALL of these; a field missing here would let the gate pass while a /uploads/
  # reference remains, then S3 deletion would 404 it permanently (not snapshot-
  # recoverable). Keep in sync with the data-editor admin forms and link/target inputs.
  RICH_TEXT_FIELDS = {
    "Block" => %w[content],
    "News" => %w[content],
    "Plan" => %w[content button_target],
    "MenuItem" => %w[link],
    "Sponsor" => %w[description],
    "Speaker" => %w[description],
    "Agenda" => %w[description],
    "Game" => %w[description],
    "Site" => %w[description indie_space_description options]
  }.freeze

  # Migration groups - ALL models are organized into groups for consistent migration
  # Single-model groups have no FK dependencies; multi-model groups must migrate together
  # Order determines migration sequence within group (parents before children)
  # fk_mappings: { "ChildModel" => { fk_column: "ParentModel" } }
  MIGRATION_GROUPS = {
    # Single-model groups (no FK dependencies)
    "slider"     => { order: %w[Slider] },
    "block"      => { order: %w[Block] },
    "plan"       => { order: %w[Plan] },
    "menu_item"  => { order: %w[MenuItem] },
    "game"       => { order: %w[Game] },
    "news"       => { order: %w[News] },
    "attachment" => { order: %w[Attachment] },

    # Multi-model groups (FK dependencies - must migrate together)
    "partner" => {
      order: %w[PartnerType Partner],
      fk_mappings: { "Partner" => { type_id: "PartnerType" } }
    },
    "sponsor" => {
      order: %w[SponsorLevel Sponsor],
      fk_mappings: { "Sponsor" => { level_id: "SponsorLevel" } }
    },
    "agenda" => {
      order: %w[AgendaDay AgendaTime Room AgendaTag Speaker Agenda AgendasSpeaker AgendasTagging],
      fk_mappings: {
        "AgendaTime" => { day_id: "AgendaDay" },
        "Agenda" => { time_id: "AgendaTime", room_id: "Room" },
        "AgendasSpeaker" => { agenda_id: "Agenda", speaker_id: "Speaker" },
        "AgendasTagging" => { agenda_id: "Agenda", agenda_tag_id: "AgendaTag" }
      }
    }
  }.freeze

  desc "Show tenant consolidation status for all groups"
  task status: :environment do
    puts "Tenant Consolidation Status"
    puts "=" * 60

    excluded = Apartment.excluded_models.map(&:to_s)

    MIGRATION_GROUPS.each do |group_name, config|
      models = config[:order]
      migrated_count = models.count { |m| excluded.include?(m) }

      status = case
      when migrated_count == models.size then "✓ COMPLETE"
      when migrated_count.positive? then "⚠ PARTIAL (#{migrated_count}/#{models.size})"
      else "○ PENDING"
      end

      puts "\n#{group_name}: #{status}"
      puts "  Models: #{models.join(', ')}"
    end

    puts ""
    puts "Commands:"
    puts "  bin/rails 'tenant_consolidation:consolidate[group]'       - Migrate group to public schema"
    puts "  bin/rails 'tenant_consolidation:consolidate[group,true]'  - Dry run"
    puts "  bin/rails 'tenant_consolidation:verify[group]'            - Verify migration status"
    puts "  bin/rails 'tenant_consolidation:rollback[group]'          - Rollback group (delete from public)"
  end

  desc "Consolidate a group of models to public schema with FK remapping"
  task :consolidate, [ :group, :dry_run ] => :environment do |_t, args|
    group_name = args[:group]
    dry_run = args[:dry_run] == "true"

    if group_name.blank?
      puts "ERROR: group argument required"
      puts "Usage: bin/rails 'tenant_consolidation:consolidate[slider]'"
      puts "       bin/rails 'tenant_consolidation:consolidate[agenda,true]'  # dry run"
      puts ""
      puts "Available groups:"
      MIGRATION_GROUPS.each do |name, config|
        puts "  #{name}: #{config[:order].join(', ')}"
      end
      exit 1
    end

    group_config = MIGRATION_GROUPS[group_name]
    if group_config.nil?
      puts "ERROR: Unknown group '#{group_name}'"
      puts "Available groups: #{MIGRATION_GROUPS.keys.join(', ')}"
      exit 1
    end

    # Sponsor moves by dump and import, with the retired Partner rows folded into it —
    # never in place, and never as standalone Partner rows.
    if %w[sponsor partner].include?(group_name)
      puts "ERROR: The '#{group_name}' group moves through the sponsor tasks, with Partner folded into Sponsor."
      puts "Run: bin/rails 'tenant_consolidation:sponsor:backup', then sponsor:migrate and sponsor:verify"
      puts "(docs/tenant/migrate_sponsor.md)"
      exit 1
    end

    # Check if any model in group is already in public
    group_config[:order].each do |model_name|
      model_class = model_name.constantize
      if model_already_in_public?(model_class)
        puts "ERROR: #{model_name} is already in public schema"
        puts "Cannot migrate group partially. All models must be migrated together."
        exit 1
      end
    end

    # Re-runs must start from a clean target. A partial/aborted run can leave rows in
    # public while the model is not yet excluded; resuming in place risks dropping rows
    # (dedup is not per-source-record) and corrupting child FKs (id_maps rebuild only on
    # a full pass). Tenant data is never deleted, so the safe re-run is rollback + redo.
    unless dry_run
      group_config[:order].each do |model_name|
        existing = Apartment::Tenant.switch("public") { model_name.constantize.unscoped.count }
        next unless existing.positive?

        puts "ERROR: #{model_name} already has #{existing} record(s) in public schema."
        puts "Re-runs must start clean. Roll back first:"
        puts "  bin/rails 'tenant_consolidation:rollback[#{group_name}]'"
        exit 1
      end
    end

    # Polymorphic references to remapped tenant models cannot be remapped in place
    # (id_maps are per-run/in-memory, and groups migrate in separate runs). Fail loud
    # rather than write dangling record_ids. See docs for the dump/transform/import path.
    abort_if_unmappable_polymorphic!(group_config)

    puts "Consolidating '#{group_name}' from tenant schemas to public..."
    puts "Models: #{group_config[:order].join(' → ')}"
    puts "(DRY RUN - no changes will be made)" if dry_run
    puts "=" * 60

    consolidate_group(group_name, group_config, dry_run: dry_run)
  end

  desc "Verify migration status for a group"
  task :verify, [ :group ] => :environment do |_t, args|
    group_name = args[:group]

    if group_name.blank?
      puts "ERROR: group argument required"
      puts "Usage: bin/rails 'tenant_consolidation:verify[slider]'"
      puts ""
      puts "Available groups:"
      MIGRATION_GROUPS.each do |name, config|
        puts "  #{name}: #{config[:order].join(', ')}"
      end
      exit 1
    end

    group_config = MIGRATION_GROUPS[group_name]
    if group_config.nil?
      puts "ERROR: Unknown group '#{group_name}'"
      puts "Available groups: #{MIGRATION_GROUPS.keys.join(', ')}"
      exit 1
    end

    puts "#{group_name.titleize} Group Verification"
    puts "=" * 60

    verify_group(group_config)
  end

  desc "Rollback consolidated records for a group (delete from public schema)"
  task :rollback, [ :group ] => :environment do |_t, args|
    group_name = args[:group]

    if group_name.blank?
      puts "ERROR: group argument required"
      puts "Usage: bin/rails 'tenant_consolidation:rollback[slider]'"
      puts ""
      puts "Available groups:"
      MIGRATION_GROUPS.each do |name, config|
        puts "  #{name}: #{config[:order].join(', ')}"
      end
      exit 1
    end

    group_config = MIGRATION_GROUPS[group_name]
    if group_config.nil?
      puts "ERROR: Unknown group '#{group_name}'"
      puts "Available groups: #{MIGRATION_GROUPS.keys.join(', ')}"
      exit 1
    end

    # Check if any model in group is still in excluded_models
    group_config[:order].each do |model_name|
      model_class = model_name.constantize
      if model_already_in_public?(model_class)
        puts "WARNING: #{model_name} is in Apartment.excluded_models"
        puts "Remove all group models from excluded_models first before rollback."
        exit 1
      end
    end

    puts "Rolling back '#{group_name}' group from public schema..."
    puts "Models: #{group_config[:order].reverse.join(' → ')} (reverse order)"
    puts "This will DELETE all records from public schema."
    puts "=" * 60

    rollback_group(group_config)
  end

  desc "Reset PostgreSQL sequences for migrated models"
  task :reset_sequences, [ :group ] => :environment do |_t, args|
    group_name = args[:group]

    if group_name.blank?
      puts "ERROR: group argument required"
      puts "Usage: bin/rails 'tenant_consolidation:reset_sequences[slider]'"
      puts ""
      puts "Available groups:"
      MIGRATION_GROUPS.each do |name, config|
        puts "  #{name}: #{config[:order].join(', ')}"
      end
      exit 1
    end

    group_config = MIGRATION_GROUPS[group_name]
    if group_config.nil?
      puts "ERROR: Unknown group '#{group_name}'"
      puts "Available groups: #{MIGRATION_GROUPS.keys.join(', ')}"
      exit 1
    end

    puts "Resetting sequences for '#{group_name}' group..."
    puts "Models: #{group_config[:order].join(', ')}"
    puts "=" * 60

    reset_sequences_for_models(group_config[:order])

    puts ""
    puts "Done. Sequences have been reset to max_id + 1."
  end

  desc "Cleanup ActiveStorage attachments for models still in tenant schemas"
  task cleanup_attachments: :environment do
    puts "Cleaning up attachments for models still in tenant schemas..."

    CONSOLIDATION_MODELS.each do |config|
      model_class = config[:model].constantize
      next if model_already_in_public?(model_class)

      Site.find_each do |site|
        Apartment::Tenant.switch(site.tenant_name) do
          ActsAsTenant.with_tenant(site) do
            purged = 0
            model_class.unscoped.find_each do |record|
              attachment = record.public_send(config[:attachment])
              next unless attachment.attached?

              attachment.purge
              purged += 1
            end
            if purged.positive?
              puts "  #{config[:model]}##{config[:field]} (#{site.tenant_name}): purged #{purged}"
            end
          end
        end
      end
    end

    puts "\nDone. Orphaned blobs will be cleaned by ActiveStorage GC."
  end

  desc "Phase 5 gate: assert nothing still depends on legacy /uploads/ before deleting S3"
  task verify_uploads_unreferenced: :environment do
    puts "Checking whether s3://<bucket>/uploads/ is safe to delete..."
    puts "=" * 60

    # This gate scans the PUBLIC schema only. If a group is not yet consolidated, its
    # rows still live in a tenant schema and would read as ~0 here — falsely "safe".
    # Refuse to run until every group is in public. (Partner/PartnerType are retired
    # via merge and never excluded, so they are not required.)
    pending = MIGRATION_GROUPS.values.flat_map { |g| g[:order] }.uniq
    pending -= %w[Partner PartnerType]
    pending = pending.reject { |m| model_already_in_public?(m.constantize) }
    if pending.any?
      puts "ERROR: not all groups consolidated (pending: #{pending.join(', ')})."
      puts "This gate is only valid once every group is in public. Aborting."
      exit 1
    end

    problems = 0

    # 1. No CKEditor rich-text field may still embed /uploads/ URLs (needs Phase 5.0
    #    rewrite). Cast each column to text so the same LIKE works for text and JSONB.
    embed_refs = 0
    RICH_TEXT_FIELDS.each do |model_name, columns|
      model_class = model_name.constantize
      columns.each do |col|
        next unless model_class.column_names.include?(col)

        quoted = model_class.connection.quote_column_name(col)
        refs = model_class.unscoped.where("#{quoted}::text LIKE ?", "%/uploads/%").count
        next unless refs.positive?

        embed_refs += refs
        puts "ERROR: #{model_name}.#{col}: #{refs} record(s) still embed /uploads/ URLs"
      end
    end
    if embed_refs.positive?
      problems += embed_refs
      puts "       Run the Phase 5.0 CKEditor URL rewrite before deleting S3 uploads."
    end

    # 2. Every record with a CarrierWave file value must have its ActiveStorage
    #    attachment in place, or its asset would be lost when /uploads/ is deleted.
    MODEL_CONFIGS.each do |config|
      model_class = config[:model].constantize
      missing = 0
      model_class.unscoped.where.not(config[:field] => [ nil, "" ]).find_each do |record|
        missing += 1 unless record.public_send(config[:attachment]).attached?
      end
      next unless missing.positive?

      problems += missing
      puts "ERROR: #{config[:model]}##{config[:field]}: #{missing} record(s) have no ActiveStorage attachment"
    end

    if problems.positive?
      puts "\nNOT SAFE: #{problems} dependency(ies) on /uploads/ remain. Do not delete S3."
      exit 1
    end

    puts "\nOK: no /uploads/ references and every asset is in ActiveStorage. Safe to delete."
  end

  desc "Attach ActiveStorage for already-public models (Site logo/figure) from CarrierWave"
  task migrate_public_assets: :environment do
    puts "Migrating assets for always-public models (e.g. Site)..."
    migrated = 0

    # Only models that no group ever consolidates (group consolidation attaches their
    # assets transactionally, with a tenant context). The Site uploaders are
    # tenant-independent, so reading them here without a tenant resolves correctly;
    # tenant-scoped uploaders would not, hence the exclusion.
    grouped = MIGRATION_GROUPS.values.flat_map { |g| g[:order] }.uniq
    always_public = MODEL_CONFIGS.reject { |c| grouped.include?(c[:model]) }

    always_public.each do |config|
      model_class = config[:model].constantize
      model_class.unscoped.find_each do |record|
        next if record.public_send(config[:attachment]).attached? # idempotent

        uploader = record.public_send(config[:field])
        next unless uploader.present?

        # Transactional: attach_asset raises on a bad/corrupt/empty download, and the
        # rollback must undo the attachment row. Without a transaction the bad blob
        # would persist, the attached? re-run guard would skip it, and the S3-deletion
        # gate (also attached?-based) would pass — losing the only original.
        ActiveRecord::Base.transaction do
          TenantConsolidation::Assets.attach_asset(record, config[:attachment], uploader.url, TenantConsolidation::Assets.source_asset_size(uploader))
        end
        migrated += 1
        print "."
      end
    end

    puts "\nDone. Attached #{migrated} asset(s)."
  end

  desc "Verify consolidated groups' assets are fully in ActiveStorage vs the tenant source (run BEFORE Phase 4.5)"
  task verify_consolidated_assets: :environment do
    puts "Comparing tenant CarrierWave asset counts to public ActiveStorage counts..."
    puts "(Authoritative — reads the physical tenant schemas directly; run before DROP SCHEMA.)"
    puts "=" * 60
    all_ok = true
    conn = ActiveRecord::Base.connection

    CONSOLIDATION_MODELS.each do |config|
      model_class = config[:model].constantize
      next unless model_already_in_public?(model_class)

      bare_table = model_class.table_name.split(".").last
      tenant_cw = tenant_marker_count(conn, bare_table, config[:field])

      # Partners merge into Sponsor, so their logos become public Sponsor attachments.
      # Count them on the tenant side too, or public_as carries a permanent +N margin
      # (the merged partners) that could mask a genuinely missing Sponsor attachment.
      tenant_cw += tenant_marker_count(conn, "partners", "logo") if config[:model] == "Sponsor"

      public_as = 0
      model_class.unscoped.find_each do |record|
        public_as += 1 if record.public_send(config[:attachment]).attached?
      end

      ok = public_as >= tenant_cw
      all_ok &&= ok
      puts "  #{config[:model]}: tenant CW=#{tenant_cw}, public AS=#{public_as} #{ok ? '✓' : '✗ MISSING ASSETS'}"
    end

    unless all_ok
      puts "\nMissing assets — do NOT proceed to Phase 4.5 / 5.5. Re-attach before tenant data is dropped."
      exit 1
    end

    puts "\nOK: every tenant CarrierWave asset has a public ActiveStorage attachment."
  end

  desc "Backfill CW marker columns from ActiveStorage (for groups consolidated before marker retention)"
  task backfill_markers: :environment do
    puts "Backfilling CW marker columns from ActiveStorage attachments..."
    filled = 0

    # Groups consolidated before marker retention (e.g. slider) have a null marker, so
    # the Phase 5 gate cannot see their assets. Record the marker now, while the AS
    # attachment is intact, so the gate can later detect an asset that goes missing.
    CONSOLIDATION_MODELS.each do |config|
      model_class = config[:model].constantize
      next unless model_already_in_public?(model_class)

      model_class.unscoped.find_each do |record|
        next if record[config[:field]].present? # idempotent

        attachment = record.public_send(config[:attachment])
        next unless attachment.attached?

        record.update_column(config[:field], attachment.filename.to_s)
        filled += 1
        print "."
      end
    end

    puts "\nDone. Backfilled #{filled} marker(s)."
  end

  desc "Backfill missing Speaker slugs from their current id (run BEFORE consolidate[agenda])"
  task :backfill_speaker_slugs, [ :dry_run ] => :environment do |_t, args|
    dry_run = args[:dry_run] == "true"

    # A speaker without a slug is reachable only through its id — FriendlyId looks the
    # slug up first and falls back to the primary key. Consolidation replaces every id,
    # and FriendlyId's before_save runs even under `save!(validate: false)`, so such a
    # row lands in public carrying a name-derived slug and its page is gone. Writing the
    # current id into the slug keeps /speakers/{id} resolving to the same person — but
    # only while those ids still mean something, which is why this runs before the move.
    if model_already_in_public?(Speaker)
      puts "ERROR: Speaker is already in Apartment.excluded_models."
      puts "       Slugs had to be backfilled before consolidate[agenda] ran; the source ids are gone."
      exit 1
    end

    puts "Backfilling Speaker slugs across all tenants..."
    puts "(DRY RUN - no changes will be made)" if dry_run
    puts "=" * 60

    filled = 0

    Site.find_each do |site|
      Apartment::Tenant.switch(site.tenant_name) do
        # unscoped: has_global_records would otherwise hide a row carrying another
        # site's id, and that row needs a slug just the same.
        taken = Speaker.unscoped.where.not(slug: [ nil, "" ]).pluck(:slug).to_set
        missing = Speaker.unscoped.where(slug: [ nil, "" ]).order(:id)
        next if missing.empty?

        puts "\n#{site.tenant_name}: #{missing.count} speaker(s) without a slug"

        missing.each do |speaker|
          slug = unique_speaker_slug(speaker, taken)
          taken << slug
          filled += 1
          puts "  ##{speaker.id} → #{slug}"
          # update_column: these rows predate today's validations, the slug is the only
          # thing being corrected, and it must not trigger FriendlyId's callbacks.
          speaker.update_column(:slug, slug) unless dry_run
        end
      end
    end

    puts "\n#{'=' * 60}"
    puts dry_run ? "Would backfill #{filled} slug(s)." : "Done. Backfilled #{filled} slug(s)."
  end

  private

  def model_already_in_public?(model_class)
    Apartment.excluded_models.map(&:to_s).include?(model_class.name)
  end

  def model_has_site_id?(model_class)
    model_class.column_names.include?("site_id")
  end

  # The id becomes the slug, unless another speaker in this tenant already uses that
  # string as a slug — /speakers/{that id} already resolves to them, not to this row,
  # so there is no URL here to preserve and any free slug will do.
  def unique_speaker_slug(speaker, taken)
    base = speaker.id.to_s
    return base unless taken.include?(base)

    suffix = 2
    suffix += 1 while taken.include?("#{base}-#{suffix}")
    "#{base}-#{suffix}"
  end

  # ============================================================
  # Group Consolidation (for models with FK dependencies)
  # ============================================================

  def consolidate_group(group_name, group_config, dry_run: false)
    models = group_config[:order]
    fk_mappings = group_config[:fk_mappings] || {}
    stats = Hash.new { |h, k| h[k] = { total: 0, migrated: 0, skipped: 0, failed: 0 } }

    Site.find_each do |site|
      puts "\nProcessing tenant: #{site.tenant_name}"

      # ID mapping: { "ModelName" => { old_id => new_id } }
      id_maps = Hash.new { |h, k| h[k] = {} }

      # Step 1: Collect all records from tenant schema with their CW URLs
      all_tenant_data = {}

      Apartment::Tenant.switch(site.tenant_name) do
        ActsAsTenant.with_tenant(site) do
          models.each do |model_name|
            model_class = model_name.constantize
            config = MODEL_CONFIGS.find { |c| c[:model] == model_name }

            all_tenant_data[model_name] = []

            model_class.unscoped.find_each do |record|
              stats[model_name][:total] += 1

              # Get CarrierWave URL + authoritative source size if model has uploads.
              # Size comes from fog (direct S3), not the CDN url — so a later download
              # through a CDN that answers 200+HTML on a missing object is caught.
              file_url = nil
              file_size = nil
              if config
                uploader = record.public_send(config[:field])
                if uploader.present?
                  file_url = uploader.url
                  file_size = TenantConsolidation::Assets.source_asset_size(uploader)
                end
              end

              # Keep the CarrierWave marker column on the migrated row. ActiveStorage is
              # the source of truth (has_migrated_upload serves AS when attached), but
              # retaining the column lets the Phase 5 gate and `verify` confirm, per
              # record, that a row which had a CW file now has an AS attachment — the
              # backstop before the irreversible S3 delete. It is also the join key for
              # the CKEditor URL rewrite (Image.find_by(file:)). Dropping it would leave
              # the gate blind. All marker columns are removed together in Phase 5.1.
              all_tenant_data[model_name] << {
                attributes: TenantConsolidation::Records.extract_raw_attributes(record),
                file_url: file_url,
                file_size: file_size,
                original_id: record.id,
                source_translations: TenantConsolidation::Records.capture_source_translations(record, model_name)
              }
            end
          end
        end
      end

      # Step 2: Create records in public schema in order, remapping FKs
      pending_assets = []

      Apartment::Tenant.switch("public") do
        ActsAsTenant.with_tenant(site) do
          ActiveRecord::Base.transaction do
            models.each do |model_name|
              model_class = model_name.constantize
              config = MODEL_CONFIGS.find { |c| c[:model] == model_name }
              model_fk_mappings = fk_mappings[model_name] || {}
              records_data = all_tenant_data[model_name] || []

              puts "\n  Migrating #{model_name} (#{records_data.size} records)..."

              records_data.each do |data|
                attrs = data[:attributes].dup

                TenantConsolidation::Records.remap_foreign_keys(attrs, model_fk_mappings, id_maps, model_name)

                if dry_run
                  # In dry run, still track hypothetical IDs for FK remapping simulation
                  id_maps[model_name][data[:original_id]] = data[:original_id]
                  stats[model_name][:migrated] += 1
                  print "."
                  next
                end

                begin
                  new_record = model_class.new
                  TenantConsolidation::Records.assign_raw_attributes(new_record, attrs)
                  new_record.site_id = site.id
                  new_record.save!(validate: false)

                  # Track ID mapping for dependent models
                  id_maps[model_name][data[:original_id]] = new_record.id

                  # Assets move after this transaction commits — see transfer_assets!
                  if data[:file_url].present? && config
                    pending_assets << {
                      record: new_record,
                      attachment: config[:attachment],
                      url: data[:file_url],
                      size: data[:file_size]
                    }
                  end

                  TenantConsolidation::Records.verify_translations_preserved(data[:source_translations], new_record, model_name)

                  stats[model_name][:migrated] += 1
                  print "."
                rescue StandardError => e
                  stats[model_name][:failed] += 1
                  puts "\n    ERROR (#{model_name}##{data[:original_id]}): #{e.message}"
                  raise # Re-raise to rollback transaction
                end
              end
            end
          end

          TenantConsolidation::Assets.transfer_assets!(pending_assets) unless dry_run
        end
      end
    end

    # Print summary
    puts "\n"
    puts "=" * 60
    puts "Group Consolidation Complete"
    puts ""

    total_failed = 0
    models.each do |model_name|
      s = stats[model_name]
      total_failed += s[:failed]
      puts "  #{model_name}:"
      puts "    Total: #{s[:total]}, Migrated: #{s[:migrated]}, Skipped: #{s[:skipped]}, Failed: #{s[:failed]}"
    end

    if total_failed.zero? && !dry_run
      # Reset PostgreSQL sequences to prevent duplicate key errors
      puts ""
      puts "Resetting sequences..."
      reset_sequences_for_models(models)

      puts ""
      puts "Next steps:"
      puts "  1. Verify group: bin/rails 'tenant_consolidation:verify[#{group_name}]'"
      puts "  2. Add ALL models to Apartment.excluded_models together:"
      models.each do |model_name|
        puts "     - #{model_name}"
      end
      puts "  3. Deploy and verify admin forms work correctly"
    end
  end

  # Abort if a group contains polymorphic references that point at remapped tenant
  # models. These cannot be remapped in place: id_maps are built per-run and groups
  # migrate in separate runs, so the parent's new id is unknown here.
  #   - Attachment#record → any model: unsafe whenever record_id is set.
  #   - News#author → expected AdminUser (public, stable id); a tenant-model
  #     author_type would be remapped and is therefore unsafe.
  def abort_if_unmappable_polymorphic!(group_config)
    models = group_config[:order]
    return unless models.include?("Attachment") || models.include?("News")

    attachment_dangling = 0
    news_foreign_author = 0
    Site.find_each do |site|
      Apartment::Tenant.switch(site.tenant_name) do
        ActsAsTenant.with_tenant(site) do
          attachment_dangling += Attachment.unscoped.where.not(record_id: nil).count if models.include?("Attachment")
          news_foreign_author += News.unscoped.where.not(author_type: [ nil, "AdminUser" ]).count if models.include?("News")
        end
      end
    end

    if attachment_dangling.positive?
      puts "ERROR: #{attachment_dangling} Attachment record(s) have a polymorphic record_id set."
      puts "Cross-group polymorphic references cannot be remapped in place."
      puts "Resolve manually, or migrate via the dump/transform/import path (see docs)."
      exit 1
    end

    if news_foreign_author.positive?
      puts "ERROR: #{news_foreign_author} News record(s) have a non-AdminUser author_type."
      puts "A polymorphic author pointing at a remapped tenant model cannot be remapped in place."
      puts "Resolve manually, or migrate via the dump/transform/import path (see docs)."
      exit 1
    end
  end

  def verify_group(group_config)
    models = group_config[:order]
    all_ok = true

    models.each do |model_name|
      model_class = model_name.constantize
      config = MODEL_CONFIGS.find { |c| c[:model] == model_name }

      puts "\n#{model_name}:"

      if model_already_in_public?(model_class)
        ok = verify_public_records(model_class)
        ok &&= verify_attachments(model_class, config) if config
      else
        ok = verify_consolidation_records(model_class)
        ok &&= verify_consolidation_attachments(model_class, config) if config
      end

      all_ok &&= ok
    end

    puts "\n" + "=" * 60
    puts all_ok ? "Group Status: ✓ OK" : "Group Status: ✗ INCOMPLETE"
  end

  def verify_public_records(model_class)
    count = model_class.unscoped.count
    puts "  Records in public: #{count}"
    true
  end

  def verify_consolidation_records(model_class)
    tenant_count = 0
    public_count = 0

    Site.find_each do |site|
      Apartment::Tenant.switch(site.tenant_name) do
        ActsAsTenant.with_tenant(site) do
          tenant_count += model_class.unscoped.count
        end
      end
    end

    Apartment::Tenant.switch("public") do
      public_count = model_class.unscoped.count
    end

    ok = public_count >= tenant_count
    puts "  Tenant: #{tenant_count}, Public: #{public_count} #{ok ? '✓' : '✗'}"
    ok
  end

  def verify_attachments(model_class, config)
    return true unless config

    field = config[:field]
    attachment = config[:attachment]
    with_cw = model_class.unscoped.where.not(field => [ nil, "" ]).count
    with_as = count_migrated_attachments(model_class, field, attachment)

    ok = with_as >= with_cw
    puts "  #{field}: CW=#{with_cw}, AS=#{with_as} #{ok ? '✓' : '✗'}"
    ok
  end

  def verify_consolidation_attachments(model_class, config)
    return true unless config

    attachment = config[:attachment]
    with_as = 0

    Apartment::Tenant.switch("public") do
      model_class.unscoped.find_each do |record|
        with_as += 1 if record.public_send(attachment).attached?
      end
    end

    puts "  With ActiveStorage: #{with_as}"
    true
  end

  def rollback_group(group_config)
    # Rollback in reverse order (children before parents for FK safety)
    models = group_config[:order].reverse
    stats = Hash.new { |h, k| h[k] = { deleted: 0, attachments_purged: 0 } }

    models.each do |model_name|
      model_class = model_name.constantize
      config = MODEL_CONFIGS.find { |c| c[:model] == model_name }
      attachment = config&.dig(:attachment)

      puts "\n  Rolling back #{model_name}..."
      model_stats = rollback_model(model_class, attachment)
      stats[model_name] = model_stats
    end

    # Print summary
    puts "\n"
    puts "=" * 60
    puts "Rollback Complete"
    puts ""

    models.each do |model_name|
      s = stats[model_name]
      puts "  #{model_name}: #{s[:deleted]} deleted, #{s[:attachments_purged]} attachments purged"
    end

    puts ""
    puts "Tenant schema data remains intact."
  end

  def rollback_model(model_class, attachment)
    count = 0
    attachments_purged = 0

    Apartment::Tenant.switch("public") do
      model_class.unscoped.find_each do |record|
        if attachment && record.public_send(attachment).attached?
          record.public_send(attachment).purge
          attachments_purged += 1
        end
        record.destroy!
        count += 1
        print "."
      end
    end

    { deleted: count, attachments_purged: attachments_purged }
  end

  # ============================================================
  # Shared Helpers
  # ============================================================

  def reset_sequences_for_models(model_names)
    model_names.each do |model_name|
      model_class = model_name.constantize

      # Use ActiveRecord's built-in method for PostgreSQL
      ActiveRecord::Base.connection.reset_pk_sequence!(model_class.table_name)

      max_id = model_class.unscoped.maximum(:id) || 0
      puts "  #{model_name}: sequence reset (max_id=#{max_id})"
    rescue StandardError => e
      puts "  #{model_name}: WARNING - Failed to reset sequence: #{e.message}"
    end
  end

  # Count rows in <tenant>.<table> with a non-blank marker column, summed across all
  # sites, reading the physical tenant schema directly (excluded models pin their table
  # name to public, so Apartment::Tenant.switch is a no-op for them).
  def tenant_marker_count(conn, bare_table, field)
    column = conn.quote_column_name(field)
    total = 0
    Site.find_each do |site|
      qualified = "#{conn.quote_table_name(site.tenant_name)}.#{conn.quote_table_name(bare_table)}"
      total += conn.select_value(
        "SELECT COUNT(*) FROM #{qualified} WHERE #{column} IS NOT NULL AND #{column} <> ''"
      ).to_i
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.cause.is_a?(PG::UndefinedTable) # absent tenant table is fine; re-raise anything else

      next
    end
    total
  end

  def already_migrated?(record, field, attachment)
    return false unless record.public_send(attachment).attached?

    uploader = record.public_send(field)
    cw_filename = File.basename(uploader.url.to_s).split("?").first rescue nil
    as_filename = record.public_send(attachment).filename.to_s rescue nil

    cw_filename.present? && cw_filename == as_filename
  end

  def count_migrated_attachments(model_class, field, attachment)
    count = 0
    model_class.unscoped.where.not(field => [ nil, "" ]).find_each do |record|
      count += 1 if already_migrated?(record, field, attachment)
    end
    count
  end
end
