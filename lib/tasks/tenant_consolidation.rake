# frozen_string_literal: true

require "open-uri"

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
    puts "  bin/rails 'tenant_consolidation:migrate_storage[Model]'   - Migrate CarrierWave to ActiveStorage"
    puts "  bin/rails 'tenant_consolidation:verify[Model]'            - Verify migration status"
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

    # Check if any model in group is already in public
    group_config[:order].each do |model_name|
      model_class = model_name.constantize
      if model_already_in_public?(model_class)
        puts "ERROR: #{model_name} is already in public schema"
        puts "Cannot migrate group partially. All models must be migrated together."
        exit 1
      end
    end

    puts "Consolidating '#{group_name}' from tenant schemas to public..."
    puts "Models: #{group_config[:order].join(' → ')}"
    puts "(DRY RUN - no changes will be made)" if dry_run
    puts "=" * 60

    consolidate_group(group_config, dry_run: dry_run)
  end

  desc "Migrate CarrierWave uploads to ActiveStorage (for models already in public schema)"
  task :migrate_storage, [ :model ] => :environment do |_t, args|
    model_name = args[:model]

    if model_name.blank?
      puts "ERROR: model argument required"
      puts "Usage: bin/rails 'tenant_consolidation:migrate_storage[Site]'"
      exit 1
    end

    model_class = model_name.constantize

    # Allow if model is in public schema OR model has no site_id (like Site itself)
    unless model_already_in_public?(model_class) || !model_has_site_id?(model_class)
      puts "ERROR: #{model_name} is still in tenant schema"
      puts "Use 'bin/rails tenant_consolidation:consolidate[group_name]' first."
      exit 1
    end

    configs = MODEL_CONFIGS.select { |c| c[:model] == model_name }
    if configs.empty?
      puts "ERROR: No upload configuration found for '#{model_name}'"
      exit 1
    end

    configs.each do |config|
      migrate_storage_for_model(model_class, config[:field], config[:attachment])
    end
  end

  desc "Verify migration status for a model"
  task :verify, [ :model ] => :environment do |_t, args|
    model_name = args[:model]

    if model_name.blank?
      puts "ERROR: model argument required"
      puts "Usage: bin/rails 'tenant_consolidation:verify[Slider]'"
      exit 1
    end

    model_class = model_name.constantize
    configs = MODEL_CONFIGS.select { |c| c[:model] == model_name }

    if configs.empty?
      puts "ERROR: No configuration found for '#{model_name}'"
      exit 1
    end

    puts "#{model_name} Migration Verification"
    puts "=" * 60

    if model_already_in_public?(model_class)
      verify_storage_migration(model_class, configs)
    else
      verify_consolidation(model_class, configs.first[:field], configs.first[:attachment])
    end
  end

  desc "Rollback consolidated records (delete from public schema)"
  task :rollback, [ :model ] => :environment do |_t, args|
    model_name = args[:model]

    if model_name.blank?
      puts "ERROR: model argument required"
      puts "Usage: bin/rails 'tenant_consolidation:rollback[Slider]'"
      exit 1
    end

    if model_name == "Site"
      puts "ERROR: Cannot rollback Site - it was never in tenant schemas"
      exit 1
    end

    config = CONSOLIDATION_MODELS.find { |c| c[:model] == model_name }
    if config.nil?
      puts "ERROR: Unknown model '#{model_name}'"
      exit 1
    end

    model_class = model_name.constantize

    if model_already_in_public?(model_class)
      puts "WARNING: #{model_name} is in Apartment.excluded_models"
      puts "Remove it from excluded_models first before rollback."
      exit 1
    end

    rollback_consolidation(model_class, config[:attachment])
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

  private

  def model_already_in_public?(model_class)
    Apartment.excluded_models.map(&:to_s).include?(model_class.name)
  end

  def model_has_site_id?(model_class)
    model_class.column_names.include?("site_id")
  end

  # ============================================================
  # Group Consolidation (for models with FK dependencies)
  # ============================================================

  def consolidate_group(group_config, dry_run: false)
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

              # Get CarrierWave URL if model has uploads
              file_url = nil
              if config
                uploader = record.public_send(config[:field])
                file_url = uploader.present? ? uploader.url : nil
              end

              all_tenant_data[model_name] << {
                attributes: record.attributes.except("id", config&.dig(:field).to_s).compact,
                file_url: file_url,
                original_id: record.id
              }
            end
          end
        end
      end

      # Step 2: Create records in public schema in order, remapping FKs
      Apartment::Tenant.switch("public") do
        ActsAsTenant.with_tenant(site) do
          models.each do |model_name|
            model_class = model_name.constantize
            config = MODEL_CONFIGS.find { |c| c[:model] == model_name }
            model_fk_mappings = fk_mappings[model_name] || {}
            records_data = all_tenant_data[model_name] || []

            puts "\n  Migrating #{model_name} (#{records_data.size} records)..."

            records_data.each do |data|
              attrs = data[:attributes].dup

              # Remap FK columns using id_maps from previously migrated models
              model_fk_mappings.each do |fk_column, parent_model|
                old_fk_value = attrs[fk_column.to_s]
                next unless old_fk_value

                new_fk_value = id_maps[parent_model][old_fk_value]
                if new_fk_value.nil?
                  puts "\n    WARNING: Cannot remap #{fk_column}=#{old_fk_value} (#{parent_model} not found in id_maps)"
                  next
                end
                attrs[fk_column.to_s] = new_fk_value
              end

              # Check for duplicates
              if record_exists?(model_class, site.id, attrs["created_at"])
                stats[model_name][:skipped] += 1
                print "s"
                next
              end

              if dry_run
                # In dry run, still track hypothetical IDs for FK remapping simulation
                id_maps[model_name][data[:original_id]] = data[:original_id]
                stats[model_name][:migrated] += 1
                print "."
                next
              end

              begin
                new_record = model_class.new(attrs)
                new_record.site_id = site.id
                new_record.save!(validate: false)

                # Track ID mapping for dependent models
                id_maps[model_name][data[:original_id]] = new_record.id

                # Attach asset if present
                if data[:file_url].present? && config
                  attach_asset(new_record, config[:attachment], data[:file_url])
                end

                stats[model_name][:migrated] += 1
                print "."
              rescue StandardError => e
                stats[model_name][:failed] += 1
                puts "\n    ERROR (#{model_name}##{data[:original_id]}): #{e.message}"
              end
            end
          end
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
      puts ""
      puts "Next steps:"
      puts "  1. Verify each model: bin/rails 'tenant_consolidation:verify[ModelName]'"
      puts "  2. Add ALL models to Apartment.excluded_models together:"
      models.each do |model_name|
        puts "     - #{model_name}"
      end
      puts "  3. Deploy and verify admin forms work correctly"
    end
  end

  def record_exists?(model_class, site_id, created_at)
    return false if created_at.nil?

    model_class.unscoped.exists?(site_id: site_id, created_at: created_at)
  end

  def verify_consolidation(model_class, field, attachment)
    tenant_count = 0
    public_count = 0
    with_attachment = 0

    # Count records in tenant schemas
    Site.find_each do |site|
      Apartment::Tenant.switch(site.tenant_name) do
        ActsAsTenant.with_tenant(site) do
          tenant_count += model_class.unscoped.count
        end
      end
    end

    # Count records in public schema
    Apartment::Tenant.switch("public") do
      public_count = model_class.unscoped.count
      model_class.unscoped.find_each do |record|
        with_attachment += 1 if record.public_send(attachment).attached?
      end
    end

    status = public_count >= tenant_count ? "OK" : "INCOMPLETE"

    puts ""
    puts "Tenant schema records:  #{tenant_count}"
    puts "Public schema records:  #{public_count}"
    puts "With ActiveStorage:     #{with_attachment}"
    puts ""
    puts "Status: #{status}"

    if public_count < tenant_count
      puts ""
      puts "WARNING: Public schema has fewer records than tenant schemas."
      puts "Run consolidation again or check for errors."
    end
  end

  def rollback_consolidation(model_class, attachment)
    puts "Rolling back #{model_class.name} consolidation..."
    puts "This will DELETE all records from public schema."
    puts ""

    count = 0
    attachments_purged = 0

    Apartment::Tenant.switch("public") do
      model_class.unscoped.find_each do |record|
        if record.public_send(attachment).attached?
          record.public_send(attachment).purge
          attachments_purged += 1
        end
        record.destroy!
        count += 1
        print "."
      end
    end

    puts "\n"
    puts "Rollback complete:"
    puts "  Records deleted:      #{count}"
    puts "  Attachments purged:   #{attachments_purged}"
    puts ""
    puts "Tenant schema data remains intact."
  end

  # ============================================================
  # Storage Migration (for models already in public schema)
  # ============================================================

  def migrate_storage_for_model(model_class, field, attachment)
    puts "\nMigrating #{model_class.name}##{field}..."

    if model_class.column_names.include?("site_id")
      # Tenant-scoped model in public schema
      migrate_tenant_scoped_storage(model_class, field, attachment)
    else
      # Non-tenant model (like Site itself)
      migrate_non_tenant_storage(model_class, field, attachment)
    end
  end

  def migrate_tenant_scoped_storage(model_class, field, attachment)
    migrated = 0
    skipped = 0
    failed = 0

    model_class.unscoped.find_each do |record|
      uploader = record.public_send(field)
      if uploader.blank? || uploader.url.blank?
        skipped += 1
        next
      end

      if already_migrated?(record, field, attachment)
        skipped += 1
        next
      end

      begin
        attach_asset(record, attachment, uploader.url)
        migrated += 1
        print "."
      rescue StandardError => e
        failed += 1
        puts "\n  ERROR: #{model_class.name}##{record.id}: #{e.message}"
      end
    end

    puts "\n  #{model_class.name}##{field}: #{migrated} migrated, #{skipped} skipped, #{failed} failed"
  end

  def migrate_non_tenant_storage(model_class, field, attachment)
    migrated = 0
    skipped = 0
    failed = 0

    model_class.unscoped.find_each do |record|
      uploader = record.public_send(field)
      if uploader.blank? || uploader.url.blank?
        skipped += 1
        next
      end

      if already_migrated?(record, field, attachment)
        skipped += 1
        next
      end

      begin
        attach_asset(record, attachment, uploader.url)
        migrated += 1
        print "."
      rescue StandardError => e
        failed += 1
        puts "\n  ERROR: #{model_class.name}##{record.id}: #{e.message}"
      end
    end

    puts "\n  #{model_class.name}##{field}: #{migrated} migrated, #{skipped} skipped, #{failed} failed"
  end

  def verify_storage_migration(model_class, configs)
    configs.each do |config|
      field = config[:field]
      attachment = config[:attachment]

      total = model_class.unscoped.count
      with_carrierwave = model_class.unscoped.where.not(field => [ nil, "" ]).count
      with_active_storage = count_migrated_attachments(model_class, field, attachment)

      missing = with_carrierwave - with_active_storage
      status = missing.zero? ? "OK" : "INCOMPLETE"

      puts ""
      puts "#{model_class.name}##{field}: #{status}"
      puts "  Total records:      #{total}"
      puts "  With CarrierWave:   #{with_carrierwave}"
      puts "  With ActiveStorage: #{with_active_storage}"
      puts "  Missing:            #{missing}" if missing.positive?
    end
  end

  # ============================================================
  # Shared Helpers
  # ============================================================

  def attach_asset(record, attachment, url)
    filename = File.basename(url).split("?").first
    content_type = Marcel::MimeType.for(name: filename)

    record.public_send(attachment).attach(
      io: URI.open(url),
      filename: filename,
      content_type: content_type
    )
  rescue StandardError => e
    puts "\n  WARNING: Failed to attach asset for #{record.class.name}##{record.id}: #{e.message}"
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
