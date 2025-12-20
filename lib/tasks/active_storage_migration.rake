# frozen_string_literal: true

namespace :active_storage_migration do
  desc "Show ActiveStorage migration readiness status"
  task migration_status: :environment do
    puts "ActiveStorage Migration Readiness"
    puts "=" * 60

    excluded = Apartment.excluded_models.map(&:to_s)

    migrations = [
      { model: Site, field: :logo },
      { model: Site, field: :figure },
      { model: Attachment, field: :file },
      { model: Speaker, field: :avatar },
      { model: Partner, field: :logo },
      { model: Sponsor, field: :logo },
      { model: Slider, field: :image },
      { model: Game, field: :thumbnail },
      { model: News, field: :thumbnail }
    ]

    migrations.each do |config|
      model_name = config[:model].name
      ready = excluded.include?(model_name)
      status = ready ? "READY" : "WAITING (in tenant schema)"
      puts "#{model_name}##{config[:field]}: #{status}"
    end

    puts ""
    puts "Models marked WAITING need acts_as_tenant migration first."
    puts "Add model to Apartment.excluded_models after data consolidation."
  end

  desc "Cleanup all ActiveStorage attachments for tenant-schema models"
  task cleanup_attachments: :environment do
    puts "Cleaning up attachments for models still in tenant schemas..."

    models = [
      { model: Speaker, field: :avatar, attachment: :avatar_attachment },
      { model: News, field: :thumbnail, attachment: :thumbnail_attachment },
      { model: Partner, field: :logo, attachment: :logo_attachment },
      { model: Sponsor, field: :logo, attachment: :logo_attachment },
      { model: Slider, field: :image, attachment: :image_attachment },
      { model: Game, field: :thumbnail, attachment: :thumbnail_attachment },
      { model: Attachment, field: :file, attachment: :file_attachment }
    ]

    Site.find_each do |site|
      puts "\nProcessing tenant: #{site.tenant_name}"

      Apartment::Tenant.switch(site.tenant_name) do
        ActsAsTenant.with_tenant(site) do
          models.each do |config|
            purged = 0
            config[:model].unscoped.find_each do |record|
              attachment = record.public_send(config[:attachment])
              next unless attachment.attached?

              attachment.purge
              purged += 1
            end
            puts "  #{config[:model].name}##{config[:field]}: purged #{purged}" if purged.positive?
          end
        end
      end
    end

    puts "\nDone. Orphaned blobs will be cleaned by ActiveStorage GC."
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

  def model_in_tenant_schema?(model)
    excluded = Apartment.excluded_models.map(&:to_s)
    !excluded.include?(model.name)
  end

  def migrate_model(model:, field:, attachment:)
    if model_in_tenant_schema?(model)
      puts "\n#{model.name}##{field}: SKIPPED (still in Apartment tenant schema)"
      puts "  → Complete acts_as_tenant migration first"
      return
    end

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
    if model_in_tenant_schema?(model)
      puts "\n#{model.name}##{field}: SKIPPED (still in Apartment tenant schema)"
      return
    end

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
