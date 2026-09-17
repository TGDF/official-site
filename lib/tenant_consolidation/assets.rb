# frozen_string_literal: true

require "open-uri"

module TenantConsolidation
  # Moving a CarrierWave file into ActiveStorage. Every step fails loud: the RDS
  # snapshot does not cover S3, so a silently bad transfer that later passed the
  # Phase 5.5 gate would lose the only original.
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
    def attach_asset(record, field, attachment, url, expected_size)
      filename = record[field]
      content_type = Marcel::MimeType.for(name: filename)

      record.public_send(attachment).attach(
        io: URI.open(url),
        filename: filename,
        content_type: content_type
      )

      # Compare the stored blob against the authoritative source size so a CDN that
      # answers 200 + an HTML error body (wrong but non-empty) is rejected.
      actual_size = record.public_send(attachment).blob&.byte_size
      if actual_size.nil? || actual_size.zero?
        raise "Empty asset downloaded for #{record.class.name}##{record.id} from #{url}"
      end
      if expected_size.nil?
        raise "Cannot verify asset integrity (source size unknown) for " \
              "#{record.class.name}##{record.id} from #{url}"
      end
      if actual_size != expected_size
        raise "Asset size mismatch for #{record.class.name}##{record.id}: " \
              "source=#{expected_size} downloaded=#{actual_size} (corrupt or wrong body) from #{url}"
      end

      # Persist the attachment with validate: false. `attach` on a persisted record only
      # auto-saves when the record is valid; a row that is invalid under current
      # validations (e.g. a tightened rule a legacy row predates) would otherwise leave
      # the attachment unsaved while the in-memory blob check above still passes — a
      # silent missing attachment. The whole task migrates with validate: false, so do
      # the same here.
      record.save!(validate: false)
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
