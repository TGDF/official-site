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

  desc "Show tenant consolidation status for all models"
  task status: :environment do
    puts "Tenant Consolidation Status"
    puts "=" * 60

    excluded = Apartment.excluded_models.map(&:to_s)

    MODEL_CONFIGS.uniq { |c| c[:model] }.each do |config|
      model_name = config[:model]
      in_public = excluded.include?(model_name)
      status = in_public ? "READY (in public schema)" : "WAITING (in tenant schema)"
      puts "#{model_name}: #{status}"
    end

    puts ""
    puts "Commands:"
    puts "  bin/rails 'tenant_consolidation:consolidate[Model]'       - Migrate tenant data to public schema"
    puts "  bin/rails 'tenant_consolidation:migrate_storage[Model]'   - Migrate CarrierWave to ActiveStorage"
    puts "  bin/rails 'tenant_consolidation:verify[Model]'            - Verify migration status"
  end

  desc "Consolidate tenant data to public schema with asset migration"
  task :consolidate, [ :model, :dry_run ] => :environment do |_t, args|
    model_name = args[:model]
    dry_run = args[:dry_run] == "true"

    if model_name.blank?
      puts "ERROR: model argument required"
      puts "Usage: bin/rails 'tenant_consolidation:consolidate[Slider]'"
      puts "       bin/rails 'tenant_consolidation:consolidate[Slider,true]'  # dry run"
      exit 1
    end

    config = CONSOLIDATION_MODELS.find { |c| c[:model] == model_name }
    if config.nil?
      if model_name == "Site"
        puts "ERROR: Site is already in public schema"
        puts "Use 'bin/rails tenant_consolidation:migrate_storage[Site]' for storage-only migration."
      else
        puts "ERROR: Unknown model '#{model_name}'"
        puts "Available models: #{CONSOLIDATION_MODELS.map { |c| c[:model] }.join(', ')}"
      end
      exit 1
    end

    model_class = model_name.constantize

    if model_already_in_public?(model_class)
      puts "#{model_name} is already in public schema (in Apartment.excluded_models)"
      puts "Use 'bin/rails tenant_consolidation:migrate_storage[#{model_name}]' for storage-only migration."
      exit 1
    end

    puts "Consolidating #{model_name} from tenant schemas to public..."
    puts "(DRY RUN - no changes will be made)" if dry_run
    puts "=" * 60

    consolidate_model(model_class, config[:field], config[:attachment], dry_run: dry_run)
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
      puts "Use 'bin/rails tenant_consolidation:consolidate[#{model_name}]' first."
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
  # Tenant Consolidation (for models in tenant schema)
  # ============================================================

  def consolidate_model(model_class, field, attachment, dry_run: false)
    stats = { total: 0, migrated: 0, skipped: 0, failed: 0 }

    Site.find_each do |site|
      puts "\nProcessing tenant: #{site.tenant_name}"

      tenant_records = []

      # Step 1: Collect records and their asset URLs while in tenant context
      Apartment::Tenant.switch(site.tenant_name) do
        ActsAsTenant.with_tenant(site) do
          model_class.unscoped.find_each do |record|
            stats[:total] += 1

            # Get CarrierWave URL while original ID is valid
            uploader = record.public_send(field)
            file_url = uploader.present? ? uploader.url : nil

            tenant_records << {
              attributes: record.attributes.except("id", field.to_s),
              file_url: file_url,
              original_id: record.id
            }
          end
        end
      end

      next if tenant_records.empty?

      # Step 2: Create records in public schema with new IDs
      Apartment::Tenant.switch("public") do
        ActsAsTenant.with_tenant(site) do
          tenant_records.each do |data|
            # Check for duplicates (simple check based on site_id + created_at)
            if record_exists?(model_class, site.id, data[:attributes]["created_at"])
              stats[:skipped] += 1
              print "s"
              next
            end

            if dry_run
              stats[:migrated] += 1
              print "."
              next
            end

            begin
              new_record = model_class.new(data[:attributes])
              new_record.site_id = site.id
              new_record.save!(validate: false)

              # Attach asset if present
              if data[:file_url].present?
                attach_asset(new_record, attachment, data[:file_url])
              end

              stats[:migrated] += 1
              print "."
            rescue StandardError => e
              stats[:failed] += 1
              puts "\n  ERROR (original_id=#{data[:original_id]}): #{e.message}"
            end
          end
        end
      end
    end

    puts "\n"
    puts "=" * 60
    puts "Consolidation Complete"
    puts "  Total tenant records: #{stats[:total]}"
    puts "  Migrated:             #{stats[:migrated]}"
    puts "  Skipped (duplicates): #{stats[:skipped]}"
    puts "  Failed:               #{stats[:failed]}"

    if stats[:failed].zero? && !dry_run
      puts ""
      puts "Next steps:"
      puts "  1. Run 'bin/rails tenant_consolidation:verify[#{model_class.name}]'"
      puts "  2. Add '#{model_class.name}' to Apartment.excluded_models"
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
