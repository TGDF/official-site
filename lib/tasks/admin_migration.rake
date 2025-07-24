namespace :admin do
  desc "Migrate admin templates to make V2 the default interface"
  task migrate_templates: :environment do
    puts "Starting admin template migration to make V2 default..."

    migration_stats = {
      erb_to_v1: 0,
      v2_to_default: 0,
      slim_to_v1: 0,
      skipped: 0,
      errors: 0
    }

    admin_views_path = Rails.root.join("app", "views", "admin")
    layouts_path = Rails.root.join("app", "views", "layouts")

    # Step 1: Rename current .erb templates to +v1.erb (legacy)
    puts "\n1. Renaming .erb templates to +v1.erb (legacy)..."
    erb_files = Dir.glob("#{admin_views_path}/**/*.html.erb") + Dir.glob("#{layouts_path}/admin.html.erb")

    erb_files.each do |erb_file|
      next if erb_file.include?("+v2.erb") || erb_file.include?("+v1.erb")

      v1_file = erb_file.gsub(".html.erb", ".html+v1.erb")

      # Skip if target already exists
      if File.exist?(v1_file)
        puts "  SKIP: #{v1_file} already exists"
        migration_stats[:skipped] += 1
        next
      end

      begin
        FileUtils.mv(erb_file, v1_file)
        puts "  MOVED: #{File.basename(erb_file)} -> #{File.basename(v1_file)}"
        migration_stats[:erb_to_v1] += 1
      rescue => e
        puts "  ERROR: Failed to move #{erb_file} - #{e.message}"
        migration_stats[:errors] += 1
      end
    end

    # Step 2: Rename current +v2.erb templates to .erb (default)
    puts "\n2. Renaming +v2.erb templates to .erb (default)..."
    v2_files = Dir.glob("#{admin_views_path}/**/*.html+v2.erb") + Dir.glob("#{layouts_path}/admin.html+v2.erb")

    v2_files.each do |v2_file|
      default_file = v2_file.gsub(".html+v2.erb", ".html.erb")

      # Skip if target already exists
      if File.exist?(default_file)
        puts "  SKIP: #{default_file} already exists"
        migration_stats[:skipped] += 1
        next
      end

      begin
        FileUtils.mv(v2_file, default_file)
        puts "  MOVED: #{File.basename(v2_file)} -> #{File.basename(default_file)}"
        migration_stats[:v2_to_default] += 1
      rescue => e
        puts "  ERROR: Failed to move #{v2_file} - #{e.message}"
        migration_stats[:errors] += 1
      end
    end

    # Step 3: Handle .slim to +v1.erb conversion for sidebar components
    puts "\n3. Converting .slim templates to +v1.erb (legacy)..."
    slim_files = Dir.glob("#{admin_views_path}/**/*.html.slim")

    slim_files.each do |slim_file|
      v1_file = slim_file.gsub(".html.slim", ".html+v1.erb")

      # Skip if target already exists
      if File.exist?(v1_file)
        puts "  SKIP: #{v1_file} already exists"
        migration_stats[:skipped] += 1
        next
      end

      begin
        # For now, just rename the .slim files to +v1.erb with a notice
        # In a real migration, you'd want to convert Slim syntax to ERB
        slim_content = File.read(slim_file)
        erb_content = "<%# CONVERTED FROM SLIM - NEEDS MANUAL ERB CONVERSION %>\n#{slim_content}"

        File.write(v1_file, erb_content)
        File.delete(slim_file)
        puts "  CONVERTED: #{File.basename(slim_file)} -> #{File.basename(v1_file)} (needs manual ERB conversion)"
        migration_stats[:slim_to_v1] += 1
      rescue => e
        puts "  ERROR: Failed to convert #{slim_file} - #{e.message}"
        migration_stats[:errors] += 1
      end
    end

    # Summary
    puts "\n" + "="*60
    puts "MIGRATION SUMMARY"
    puts "="*60
    puts "✓ ERB -> V1 legacy:     #{migration_stats[:erb_to_v1]} files"
    puts "✓ V2 -> Default:        #{migration_stats[:v2_to_default]} files"
    puts "✓ Slim -> V1 legacy:    #{migration_stats[:slim_to_v1]} files"
    puts "- Skipped:              #{migration_stats[:skipped]} files"
    puts "✗ Errors:               #{migration_stats[:errors]} files"
    puts "="*60

    if migration_stats[:errors] == 0
      puts "✅ Migration completed successfully!"
      puts "💡 Note: Slim files converted to +v1.erb need manual ERB syntax conversion"
    else
      puts "⚠️  Migration completed with #{migration_stats[:errors]} errors"
      puts "Please review the errors above and resolve them manually"
    end

    puts "\nNext steps:"
    puts "1. Update controller logic to use admin_v1_legacy feature flag"
    puts "2. Verify all admin pages render correctly"
    puts "3. Run tests to ensure everything works"
  end

  desc "Verify admin template migration results"
  task verify_migration: :environment do
    puts "Verifying admin template migration..."

    admin_views_path = Rails.root.join("app", "views", "admin")
    layouts_path = Rails.root.join("app", "views", "layouts")

    # Check for remaining +v2.erb files (should be none)
    v2_files = Dir.glob("#{admin_views_path}/**/*.html+v2.erb") + Dir.glob("#{layouts_path}/admin.html+v2.erb")

    # Check for .slim files (should be none in admin)
    slim_files = Dir.glob("#{admin_views_path}/**/*.html.slim")

    # Count default .erb files
    erb_files = Dir.glob("#{admin_views_path}/**/*.html.erb") + Dir.glob("#{layouts_path}/admin.html.erb")
    erb_files = erb_files.reject { |f| f.include?("+v1.erb") }

    # Count legacy +v1.erb files
    v1_files = Dir.glob("#{admin_views_path}/**/*.html+v1.erb") + Dir.glob("#{layouts_path}/admin.html+v1.erb")

    puts "\nTemplate structure after migration:"
    puts "✓ Default templates (.erb):     #{erb_files.count}"
    puts "✓ Legacy templates (+v1.erb):   #{v1_files.count}"
    puts "⚠ Remaining V2 templates:       #{v2_files.count} (should be 0)"
    puts "⚠ Remaining Slim templates:     #{slim_files.count} (should be 0)"

    if v2_files.any?
      puts "\nRemaining +v2.erb files:"
      v2_files.each { |f| puts "  - #{f}" }
    end

    if slim_files.any?
      puts "\nRemaining .slim files:"
      slim_files.each { |f| puts "  - #{f}" }
    end

    if v2_files.empty? && slim_files.empty?
      puts "\n✅ Migration verification successful!"
    else
      puts "\n⚠️  Migration needs attention - see files listed above"
    end
  end
end
