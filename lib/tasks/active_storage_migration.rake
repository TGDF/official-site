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

    if model.column_names.include?("site_id") || model.respond_to?(:acts_as_tenant?)
      Site.find_each do |site|
        ActsAsTenant.with_tenant(site) do
          migrate_records(model, field, attachment, tenant: site.tenant_name)
        end
      end

      ActsAsTenant.without_tenant do
        migrate_records(model, field, attachment, tenant: "global")
      end
    else
      migrate_records(model, field, attachment, tenant: nil)
    end
  end

  def migrate_records(model, field, attachment, tenant:)
    scope = model.unscoped
    total = scope.count
    migrated = 0
    skipped = 0
    failed = 0

    scope.find_each do |record|
      if record.public_send(attachment).attached?
        skipped += 1
        next
      end

      uploader = record.public_send(field)
      if uploader.blank? || uploader.url.blank?
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
    total = model.unscoped.count
    with_carrierwave = model.unscoped.where.not(field => [ nil, "" ]).count
    with_active_storage = model.unscoped.joins("INNER JOIN active_storage_attachments ON " \
      "active_storage_attachments.record_type = '#{model.name}' AND " \
      "active_storage_attachments.record_id = #{model.table_name}.id AND " \
      "active_storage_attachments.name = '#{attachment}'").count

    missing = with_carrierwave - with_active_storage
    status = missing.zero? ? "OK" : "INCOMPLETE"

    puts ""
    puts "#{model.name}##{field}: #{status}"
    puts "  Total records:      #{total}"
    puts "  With CarrierWave:   #{with_carrierwave}"
    puts "  With ActiveStorage: #{with_active_storage}"
    puts "  Missing:            #{missing}" if missing.positive?
  end
end
