# frozen_string_literal: true

class AttachmentUploader < CarrierWave::Uploader::Base
  include HasUploaderTenant

  def store_dir
    "uploads/#{tenant_name}" \
      "/#{model.class.to_s.underscore}" \
      "/#{mounted_as}/#{model.id}"
  end
end
