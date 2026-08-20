# frozen_string_literal: true

module HasMigratedUpload
  extend ActiveSupport::Concern

  class_methods do
    def has_migrated_upload(field, variants: {}, attachment_name: nil, validates_presence: false)
      attachment_name ||= :"#{field}_attachment"

      has_one_attached attachment_name

      if validates_presence
        options = validates_presence.is_a?(Hash) ? validates_presence : {}
        # A pending removal counts as blank here rather than inside <field>_present?,
        # so the predicate keeps meaning "a file is stored" — the admin forms gate the
        # preview and the removal checkbox on it, and a rejected removal must still
        # show both.
        validate(**options) do
          kept = public_send(:"#{field}_present?") && !public_send(:"#{field}_marked_for_removal?")
          errors.add(field, :blank) unless kept
        end
      end

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

      # Writing follows the same routing as reading. A model still in a tenant schema
      # must go to CarrierWave: active_storage_attachments is one shared public table
      # keyed by record_id, and that id only becomes unique once the group has moved —
      # before then the same id exists in every tenant schema.
      define_method(:"#{field}_upload=") do |uploaded|
        return public_send(:"#{field}=", uploaded) if model_in_tenant_schema?

        public_send(attachment_name).attach(uploaded)
      end

      define_method(:"#{field}_filename") do
        attachment = public_send(attachment_name)
        return attachment.filename.to_s if !model_in_tenant_schema? && attachment.attached?

        public_send(field).filename
      end

      # CarrierWave's remove_<field> checkbox clears only its own column, but for a
      # model in the public schema it is the ActiveStorage attachment that <field>_url
      # serves — so the checkbox has to reach that attachment too, or "remove" leaves
      # the file in place. A file supplied in the same request is a replacement, not a
      # removal, and wins.
      define_method(:"#{field}_marked_for_removal?") do
        return false unless respond_to?(:"remove_#{field}?")
        return false unless public_send(:"remove_#{field}?")

        !public_send(attachment_name).attachment&.new_record?
      end

      # Removal is only *pending* until the save commits, so a required upload can
      # still refuse to be emptied and the blob survives a rejected form. Purging
      # after commit also keeps a rolled-back save from destroying the only original.
      # The intent is captured at validation time because CarrierWave consumes its own
      # remove flag in a before_save — by after_save there is nothing left to read.
      after_validation do
        next unless errors.empty?
        next unless public_send(:"#{field}_marked_for_removal?")

        (@pending_upload_purges ||= {})[attachment_name] = true
      end

      after_commit do
        next unless @pending_upload_purges&.delete(attachment_name)

        attachment = public_send(attachment_name)
        attachment.purge if attachment.attached?
      end
    end
  end

  private

  def model_in_tenant_schema?
    !apartment_excluded_model?
  end

  def apartment_excluded_model?
    # excluded_models lists base classes; an STI subclass (Image, IndieSpace::Game,
    # NightMarket::Game) must resolve via base_class or it would be treated as still
    # in the tenant schema after its group is consolidated, serving the wrong storage.
    Apartment.excluded_models.map(&:to_s).include?(self.class.base_class.name)
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
