# frozen_string_literal: true

module HasMigratedUpload
  extend ActiveSupport::Concern

  class_methods do
    def has_migrated_upload(field, variants: {}, attachment_name: nil)
      attachment_name ||= :"#{field}_attachment"

      has_one_attached attachment_name

      define_method(:"#{field}_url") do |version = nil|
        attachment = public_send(attachment_name)

        # Use ActiveStorage if:
        # 1. active_storage_read is enabled and attachment exists, OR
        # 2. active_storage_write is enabled and attachment exists (so we can read what we wrote)
        use_active_storage = attachment.attached? &&
                             (Flipper.enabled?(:active_storage_read) || Flipper.enabled?(:active_storage_write))

        if use_active_storage
          active_storage_url_for(attachment, version, variants)
        else
          carrierwave_url_for(field, version)
        end
      end

      define_method(:"#{field}_present?") do
        attachment = public_send(attachment_name)
        attachment.attached? || read_attribute(field).present?
      end

      # Override CarrierWave's store callback to skip S3 requests when file hasn't changed
      define_method(:"store_#{field}!") do
        attachment = public_send(attachment_name)

        # Skip CarrierWave if ActiveStorage is managing this file
        return if attachment.attached? && Flipper.enabled?(:active_storage_write)

        # Skip if file wasn't changed (no new upload, no removal)
        return unless previous_changes.key?(field.to_s) ||
                      previous_changes.key?("#{field}_cache") ||
                      send(:"remove_#{field}?")

        super()
      end
    end
  end

  private

  def active_storage_url_for(attachment, version, variants)
    return unless attachment.attached?

    if version && variants[version]
      attachment.variant(variants[version])
    else
      attachment
    end
  end

  def carrierwave_url_for(field, version)
    uploader = public_send(field)

    if version && read_attribute(field).present?
      uploader.public_send(version).url
    else
      uploader.url
    end
  end
end
