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

  # Translated attributes per model (for verification during migration)
  # These use Mobility JSONB backend and need raw column access to preserve all locales
  TRANSLATED_ATTRS = {
    "Plan" => %w[name content button_label button_target],
    "Sponsor" => %w[name description],
    "SponsorLevel" => %w[name],
    "Partner" => %w[name description],
    "PartnerType" => %w[name],
    "Game" => %w[name description team],
    "News" => %w[title content],
    "Speaker" => %w[name title description],
    "Agenda" => %w[subject description],
    "AgendaTag" => %w[name],
    "MenuItem" => %w[name link]
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

  desc "Merge Partner/PartnerType to Sponsor/SponsorLevel during consolidation"
  task :merge_partner_to_sponsor, [ :dry_run ] => :environment do |_t, args|
    dry_run = args[:dry_run] == "true"
    puts "Merging Partner → Sponsor across all tenants..."
    puts "(DRY RUN - no changes will be made)" if dry_run

    stats = { types_created: 0, types_matched: 0, partners_merged: 0, skipped: 0, failed: 0 }

    Site.find_each do |site|
      puts "\nProcessing tenant: #{site.tenant_name}"

      # Collect Partner data from tenant schema (with CW URLs)
      partner_data = []
      type_data = []

      Apartment::Tenant.switch(site.tenant_name) do
        ActsAsTenant.with_tenant(site) do
          PartnerType.unscoped.find_each do |pt|
            type_data << { id: pt.id, name: pt[:name], order: pt.order }
          end

          Partner.unscoped.find_each do |p|
            partner_data << {
              attributes: extract_raw_attributes(p, "logo", "type_id"),
              type_id: p.type_id,
              logo_url: p.logo.present? ? p.logo.url : nil,
              source_translations: capture_source_translations(p, "Partner")
            }
          end
        end
      end

      next if partner_data.empty?

      # Create in public schema
      Apartment::Tenant.switch("public") do
        ActsAsTenant.with_tenant(site) do
          ActiveRecord::Base.transaction do
            # Map PartnerType -> SponsorLevel (by name)
            type_to_level = {}
            type_data.each do |td|
              existing = SponsorLevel.find_by(site_id: site.id, name: td[:name])
              if existing
                type_to_level[td[:id]] = existing
                stats[:types_matched] += 1
                puts "  SponsorLevel '#{td[:name]}' already exists"
              else
                if dry_run
                  type_to_level[td[:id]] = OpenStruct.new(id: td[:id], name: td[:name])
                  stats[:types_created] += 1
                else
                  level = SponsorLevel.create!(site_id: site.id, name: td[:name], order: td[:order])
                  type_to_level[td[:id]] = level
                  stats[:types_created] += 1
                end
                puts "  Created SponsorLevel '#{td[:name]}'"
              end
            end

            # Merge Partners -> Sponsors
            partner_data.each do |pd|
              level = type_to_level[pd[:type_id]]

              # Check for duplicate by name
              if Sponsor.exists?(site_id: site.id, name: pd[:attributes]["name"])
                puts "  SKIP: Sponsor '#{pd[:attributes]["name"]}' already exists (manual review needed)"
                stats[:skipped] += 1
                next
              end

              if dry_run
                stats[:partners_merged] += 1
                print "."
                next
              end

              begin
                sponsor = Sponsor.new
                assign_raw_attributes(sponsor, pd[:attributes])
                sponsor.site_id = site.id
                sponsor.level = level
                sponsor.save!(validate: false)

                if pd[:logo_url].present?
                  attach_asset(sponsor, :logo_attachment, pd[:logo_url])
                end

                # Post-migration verification
                verify_translations_preserved(pd[:source_translations], sponsor, "Sponsor")
                if pd[:logo_url].present?
                  verify_attachment_migrated(sponsor, { attachment: :logo_attachment }, pd[:logo_url])
                end

                stats[:partners_merged] += 1
                print "."
              rescue StandardError => e
                stats[:failed] += 1
                puts "\n  ERROR: #{e.message}"
                raise # Re-raise to rollback transaction
              end
            end
          end
        end
      end
    end

    puts "\n\n#{"=" * 60}"
    puts "Merge Complete"
    puts "  SponsorLevels created: #{stats[:types_created]}"
    puts "  SponsorLevels matched: #{stats[:types_matched]}"
    puts "  Partners merged:       #{stats[:partners_merged]}"
    puts "  Skipped (duplicates):  #{stats[:skipped]}"
    puts "  Failed:                #{stats[:failed]}"
  end

  private

  def model_already_in_public?(model_class)
    Apartment.excluded_models.map(&:to_s).include?(model_class.name)
  end

  def model_has_site_id?(model_class)
    model_class.column_names.include?("site_id")
  end

  # Extract raw attributes bypassing Mobility's attribute_methods plugin
  # This preserves full JSONB content with all locales instead of current locale only
  def extract_raw_attributes(record, *excluded_fields)
    excluded = [ "id" ] + excluded_fields.compact.map(&:to_s)
    record.attribute_names
          .reject { |name| excluded.include?(name) }
          .to_h { |name| [ name, record[name] ] }
          .compact
  end

  # Capture translated attribute values while in tenant schema for later verification
  def capture_source_translations(record, model_name)
    translated_attrs = TRANSLATED_ATTRS[model_name] || []
    translated_attrs.to_h { |attr| [ attr, record[attr] ] }
  end

  # Verify that all locale keys are preserved after migration
  def verify_translations_preserved(source_translations, new_record, model_name)
    translated_attrs = TRANSLATED_ATTRS[model_name] || []
    translated_attrs.each do |attr|
      source_locales = (source_translations[attr] || {}).keys.sort
      new_locales = (new_record[attr] || {}).keys.sort
      if source_locales != new_locales
        raise "Translation loss detected for #{model_name}##{new_record.id}.#{attr}: " \
              "expected #{source_locales}, got #{new_locales}"
      end
    end
  end

  # Verify that attachment was successfully migrated
  def verify_attachment_migrated(new_record, config, source_url)
    return true unless source_url.present? && config

    attachment = new_record.public_send(config[:attachment])
    unless attachment.attached?
      raise "Attachment not migrated for #{new_record.class.name}##{new_record.id}"
    end
    true
  end

  # Assign attributes bypassing Mobility's writer plugin
  # This preserves full JSONB content with all locales
  def assign_raw_attributes(record, attrs)
    attrs.each do |attr, value|
      record[attr] = value
    end
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

              # Get CarrierWave URL if model has uploads
              file_url = nil
              if config
                uploader = record.public_send(config[:field])
                file_url = uploader.present? ? uploader.url : nil
              end

              all_tenant_data[model_name] << {
                attributes: extract_raw_attributes(record, config&.dig(:field).to_s),
                file_url: file_url,
                original_id: record.id,
                source_translations: capture_source_translations(record, model_name)
              }
            end
          end
        end
      end

      # Step 2: Create records in public schema in order, remapping FKs
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
                  new_record = model_class.new
                  assign_raw_attributes(new_record, attrs)
                  new_record.site_id = site.id
                  new_record.save!(validate: false)

                  # Track ID mapping for dependent models
                  id_maps[model_name][data[:original_id]] = new_record.id

                  # Attach asset if present
                  if data[:file_url].present? && config
                    attach_asset(new_record, config[:attachment], data[:file_url])
                  end

                  # Post-migration verification
                  verify_translations_preserved(data[:source_translations], new_record, model_name)
                  if data[:file_url].present? && config
                    verify_attachment_migrated(new_record, config, data[:file_url])
                  end

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
      puts "  1. Verify group: bin/rails 'tenant_consolidation:verify[#{group_name}]'"
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
