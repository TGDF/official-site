# frozen_string_literal: true

module HasMigratedUpload
  extend ActiveSupport::Concern

  class_methods do
    def has_migrated_upload(field, variants: {}, attachment_name: nil)
      attachment_name ||= :"#{field}_attachment"

      has_one_attached attachment_name

      define_method(:"#{field}_url") do |version = nil|
        # Models still in Apartment tenant schema must use CarrierWave
        # to avoid cross-tenant attachment collisions
        return carrierwave_url_for(field, version) if model_in_tenant_schema?

        # Models in public schema: use ActiveStorage if attached, otherwise fallback to CarrierWave
        attachment = public_send(attachment_name)

        if attachment.attached?
          active_storage_url_for(attachment, version, variants)
        else
          carrierwave_url_for(field, version)
        end
      end

      define_method(:"#{field}_present?") do
        attachment = public_send(attachment_name)
        attachment.attached? || public_send(field).present?
      end
    end
  end

  private

  def model_in_tenant_schema?
    excluded = Apartment.excluded_models.map(&:to_s)
    !excluded.include?(self.class.name)
  end

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

    if version
      uploader.public_send(version).url
    else
      uploader.url
    end
  end
end
