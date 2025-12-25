# frozen_string_literal: true

namespace :active_storage do
  desc "Analyze pending blobs one-by-one (safe for low CPU environments)"
  task analyze_pending: :environment do
    # Re-enable analyzers for this task
    Rails.application.config.active_storage.analyzers = [
      ActiveStorage::Analyzer::ImageAnalyzer::Vips,
      ActiveStorage::Analyzer::VideoAnalyzer
    ]

    blobs = ActiveStorage::Blob.where.not("metadata ? 'analyzed'")
    total = blobs.count

    puts "Found #{total} blobs pending analysis"

    blobs.find_each.with_index do |blob, index|
      print "[#{index + 1}/#{total}] Analyzing blob #{blob.id} (#{blob.filename})..."
      blob.analyze
      puts " done (#{blob.metadata['width']}x#{blob.metadata['height']})"
    rescue => e
      puts " error: #{e.message}"
    end

    puts "Analysis complete"
  end
end
