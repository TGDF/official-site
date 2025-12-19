# frozen_string_literal: true

namespace :active_storage_migration do
  desc "Setup feature flags for ActiveStorage migration"
  task setup_flags: :environment do
    puts "Setting up ActiveStorage migration feature flags..."

    Flipper.add(:active_storage_read)
    Flipper.add(:active_storage_write)

    puts "Feature flags created:"
    puts "  - active_storage_read: #{Flipper.enabled?(:active_storage_read) ? 'enabled' : 'disabled'}"
    puts "  - active_storage_write: #{Flipper.enabled?(:active_storage_write) ? 'enabled' : 'disabled'}"
    puts ""
    puts "To enable reading from ActiveStorage:"
    puts "  Flipper.enable(:active_storage_read)"
    puts ""
    puts "To enable writing to ActiveStorage:"
    puts "  Flipper.enable(:active_storage_write)"
  end

  desc "Enable ActiveStorage read (serve files from ActiveStorage if available)"
  task enable_read: :environment do
    Flipper.enable(:active_storage_read)
    puts "ActiveStorage read enabled - files will be served from ActiveStorage when available"
  end

  desc "Enable ActiveStorage write (new uploads go to ActiveStorage)"
  task enable_write: :environment do
    Flipper.enable(:active_storage_write)
    puts "ActiveStorage write enabled - new uploads will go to ActiveStorage"
  end

  desc "Disable ActiveStorage read (fallback to CarrierWave)"
  task disable_read: :environment do
    Flipper.disable(:active_storage_read)
    puts "ActiveStorage read disabled - falling back to CarrierWave"
  end

  desc "Disable ActiveStorage write (new uploads go to CarrierWave)"
  task disable_write: :environment do
    Flipper.disable(:active_storage_write)
    puts "ActiveStorage write disabled - new uploads go to CarrierWave"
  end

  desc "Show current migration status"
  task status: :environment do
    puts "ActiveStorage Migration Status"
    puts "=" * 40
    puts "Feature Flags:"
    puts "  active_storage_read:  #{Flipper.enabled?(:active_storage_read) ? 'ENABLED' : 'disabled'}"
    puts "  active_storage_write: #{Flipper.enabled?(:active_storage_write) ? 'ENABLED' : 'disabled'}"
    puts ""
  end

  desc "Migrate CarrierWave uploads to ActiveStorage"
  task migrate: :environment do
    require "open-uri"

    migrations = [
      { model: Attachment, field: :file, attachment: :file_attachment },
      { model: Site, field: :logo, attachment: :logo_attachment },
      { model: Site, field: :figure, attachment: :figure_attachment },
      { model: Speaker, field: :avatar, attachment: :avatar_attachment },
      { model: Partner, field: :logo, attachment: :logo_attachment },
      { model: Sponsor, field: :logo, attachment: :logo_attachment },
      { model: Slider, field: :image, attachment: :image_attachment },
      { model: Game, field: :thumbnail, attachment: :thumbnail_attachment },
      { model: News, field: :thumbnail, attachment: :thumbnail_attachment }
    ]

    model_filter = ENV["MODEL"]

    migrations.each do |config|
      next if model_filter && config[:model].name != model_filter

      migrate_model(**config)
    end
  end

  desc "Verify migration completeness"
  task verify: :environment do
    verifications = [
      { model: Attachment, field: :file, attachment: :file_attachment },
      { model: Site, field: :logo, attachment: :logo_attachment },
      { model: Site, field: :figure, attachment: :figure_attachment },
      { model: Speaker, field: :avatar, attachment: :avatar_attachment },
      { model: Partner, field: :logo, attachment: :logo_attachment },
      { model: Sponsor, field: :logo, attachment: :logo_attachment },
      { model: Slider, field: :image, attachment: :image_attachment },
      { model: Game, field: :thumbnail, attachment: :thumbnail_attachment },
      { model: News, field: :thumbnail, attachment: :thumbnail_attachment }
    ]

    model_filter = ENV["MODEL"]

    puts "Migration Verification Report"
    puts "=" * 60

    verifications.each do |config|
      next if model_filter && config[:model].name != model_filter

      verify_model(**config)
    end
  end

  def migrate_model(model:, field:, attachment:)
    puts "\nMigrating #{model.name}##{field}..."

    if model.column_names.include?("site_id") || model.respond_to?(:scoped_by_tenant?)
      # Scenario 1: Tenant-scoped records (per-tenant data)
      Site.find_each do |site|
        Apartment::Tenant.switch(site.tenant_name) do
          ActsAsTenant.with_tenant(site) do
            migrate_records(model, field, attachment, tenant: site.tenant_name)
          end
        end
      end

      # Scenario 2: Global records (site_id IS NULL, but exist in tenant schemas)
      Site.find_each do |site|
        Apartment::Tenant.switch(site.tenant_name) do
          ActsAsTenant.without_tenant do
            migrate_global_records(model, field, attachment, tenant: "#{site.tenant_name}/global")
          end
        end
      end
    else
      # Scenario 3: Non-tenant models (Site itself - in public schema)
      migrate_records(model, field, attachment, tenant: nil)
    end
  end

  def migrate_global_records(model, field, attachment, tenant:)
    scope = model.unscoped.where(site_id: nil)
    total = scope.count
    return if total.zero?

    migrated = 0
    skipped = 0
    failed = 0

    scope.find_each do |record|
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
        url = uploader.url
        filename = File.basename(url).split("?").first
        content_type = Marcel::MimeType.for(name: filename)

        record.public_send(attachment).attach(
          io: URI.open(url),
          filename: filename,
          content_type: content_type
        )

        migrated += 1
        print "."
      rescue StandardError => e
        failed += 1
        puts "\n  ERROR: #{model.name}##{record.id}: #{e.message}"
      end
    end

    puts "\n  #{model.name} (#{tenant}): #{migrated} migrated, #{skipped} skipped, #{failed} failed" if migrated.positive? || failed.positive?
  end

  def migrate_records(model, field, attachment, tenant:)
    scope = model.unscoped
    total = scope.count
    migrated = 0
    skipped = 0
    failed = 0

    scope.find_each do |record|
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
        url = uploader.url
        filename = File.basename(url).split("?").first
        content_type = Marcel::MimeType.for(name: filename)

        record.public_send(attachment).attach(
          io: URI.open(url),
          filename: filename,
          content_type: content_type
        )

        migrated += 1
        print "."
      rescue StandardError => e
        failed += 1
        puts "\n  ERROR: #{model.name}##{record.id}: #{e.message}"
      end
    end

    tenant_info = tenant ? " (#{tenant})" : ""
    puts "\n  #{model.name}#{tenant_info}: #{migrated} migrated, #{skipped} skipped, #{failed} failed"
  end

  def verify_model(model:, field:, attachment:)
    if model.column_names.include?("site_id") || model.respond_to?(:scoped_by_tenant?)
      verify_tenant_model(model: model, field: field, attachment: attachment)
    else
      verify_non_tenant_model(model: model, field: field, attachment: attachment)
    end
  end

  def verify_tenant_model(model:, field:, attachment:)
    puts ""
    puts "#{model.name}##{field}:"

    grand_total = 0
    grand_carrierwave = 0
    grand_active_storage = 0

    Site.find_each do |site|
      Apartment::Tenant.switch(site.tenant_name) do
        total = model.unscoped.count
        with_carrierwave = model.unscoped.where.not(field => [ nil, "" ]).count
        with_active_storage = count_migrated_attachments(model, field, attachment)

        next if total.zero?

        grand_total += total
        grand_carrierwave += with_carrierwave
        grand_active_storage += with_active_storage

        missing = with_carrierwave - with_active_storage
        status = missing.zero? ? "OK" : "INCOMPLETE"

        puts "  [#{site.tenant_name}] #{status} - Total: #{total}, CW: #{with_carrierwave}, AS: #{with_active_storage}" +
             (missing.positive? ? ", Missing: #{missing}" : "")
      end
    end

    grand_missing = grand_carrierwave - grand_active_storage
    grand_status = grand_missing.zero? ? "OK" : "INCOMPLETE"

    puts "  " + ("-" * 50)
    puts "  TOTAL: #{grand_status} - Total: #{grand_total}, CW: #{grand_carrierwave}, AS: #{grand_active_storage}" +
         (grand_missing.positive? ? ", Missing: #{grand_missing}" : "")
  end

  def verify_non_tenant_model(model:, field:, attachment:)
    total = model.unscoped.count
    with_carrierwave = model.unscoped.where.not(field => [ nil, "" ]).count
    with_active_storage = count_migrated_attachments(model, field, attachment)

    missing = with_carrierwave - with_active_storage
    status = missing.zero? ? "OK" : "INCOMPLETE"

    puts ""
    puts "#{model.name}##{field}: #{status}"
    puts "  Total records:      #{total}"
    puts "  With CarrierWave:   #{with_carrierwave}"
    puts "  With ActiveStorage: #{with_active_storage}"
    puts "  Missing:            #{missing}" if missing.positive?
  end

  # Check if this specific record was already migrated by comparing filenames
  # This is necessary because ActiveStorage attachments in public schema can't
  # distinguish between records with the same ID in different tenant schemas
  def already_migrated?(record, field, attachment)
    return false unless record.public_send(attachment).attached?

    uploader = record.public_send(field)
    cw_filename = File.basename(uploader.url.to_s).split("?").first rescue nil
    as_filename = record.public_send(attachment).filename.to_s rescue nil

    cw_filename.present? && cw_filename == as_filename
  end

  # Count attachments by verifying CarrierWave filename matches ActiveStorage blob
  def count_migrated_attachments(model, field, attachment)
    count = 0
    model.unscoped.where.not(field => [ nil, "" ]).find_each do |record|
      count += 1 if already_migrated?(record, field, attachment)
    end
    count
  end
end
