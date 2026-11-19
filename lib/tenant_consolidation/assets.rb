# frozen_string_literal: true

require "open-uri"

module TenantConsolidation
  # Moving a CarrierWave file into ActiveStorage. Every step fails loud: a silently
  # bad transfer passes every later check that only asks whether an attachment
  # exists, and shows only once Phase 5 removes the uploader that reads the original.
  module Assets
    module_function

    # Authoritative source size via fog (direct S3), used to verify the download.
    def source_asset_size(uploader)
      uploader.file&.size
    rescue StandardError
      nil
    end

    # Runs after the rows have committed, one transaction per asset: a download is
    # network I/O and must not hold a tenant's row transaction open (130 files for one
    # production tenant's games). A bad download rolls back only its own attachment, so
    # a failed run leaves the rows in public with some assets missing — recovered by
    # rollback[group] and redo, since the tenant source is never deleted.
    def transfer_assets!(pending)
      return if pending.empty?

      puts "\n  Transferring #{pending.size} asset(s)..."

      pending.each do |asset|
        ActiveRecord::Base.transaction do
          attach_asset(asset[:record], asset[:field], asset[:attachment], asset[:url], asset[:size])
          verify_attachment_migrated(asset[:record], { attachment: asset[:attachment] }, asset[:url])
        end
        print "."
      end
    end

    # The blob is named by the CarrierWave column itself: a stored URL percent-encodes
    # any name that is not ASCII, and that encoding is not the file's name.
    #
    # The blob is uploaded and analyzed before it is attached. Attaching an io would
    # upload only after the commit and leave analysis to the AnalyzeJob the commit
    # enqueues, which runs on the in-process :async adapter and dies with the task that
    # queued it; a blob already analyzed when its attachment commits enqueues nothing.
    # An image vips cannot read still analyzes, only without width and height.
    def attach_asset(record, field, attachment, url, expected_size)
      filename = record[field]
      blob = ActiveStorage::Blob.create_and_upload!(
        io: URI.open(url),
        filename: filename,
        content_type: Marcel::MimeType.for(name: filename)
      )
      store_blob(blob, record, attachment, url, expected_size)
    rescue StandardError
      # The file is already in the service; a failure from here on would leave it
      # there with no row pointing at it.
      blob&.purge
      raise
    end

    def store_blob(blob, record, attachment, url, expected_size)
      verify_blob_size!(blob, record, url, expected_size)
      blob.analyze

      # Assigned, then saved with validate: false like every row of the move. `attach`
      # would validate the record first: a legacy row invalid under today's rules would
      # keep its attachment unsaved, and one whose validation cannot even read it (a
      # null translated column) would raise.
      record.public_send(:"#{attachment}=", blob)
      record.save!(validate: false)
    end

    # Compare the stored blob against the authoritative source size so a CDN that
    # answers 200 + an HTML error body (wrong but non-empty) is rejected.
    def verify_blob_size!(blob, record, url, expected_size)
      problem =
        if blob.byte_size.zero?
          "Empty asset downloaded for #{record.class.name}##{record.id} from #{url}"
        elsif expected_size.nil?
          "Cannot verify asset integrity (source size unknown) for #{record.class.name}##{record.id} from #{url}"
        elsif blob.byte_size != expected_size
          "Asset size mismatch for #{record.class.name}##{record.id}: " \
            "source=#{expected_size} downloaded=#{blob.byte_size} (corrupt or wrong body) from #{url}"
        end
      raise problem if problem
    end

    def verify_attachment_migrated(new_record, config, source_url)
      return true unless source_url.present? && config

      attachment = new_record.public_send(config[:attachment])
      unless attachment.attached?
        raise "Attachment not migrated for #{new_record.class.name}##{new_record.id}"
      end
      true
    end
  end
end
