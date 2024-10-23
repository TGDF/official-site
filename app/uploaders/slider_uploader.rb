# frozen_string_literal: true

class SliderUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include HasUploaderTenant

  def store_dir
    "uploads/#{tenant_name}" \
      "/#{model.class.to_s.underscore}" \
      "/#{mounted_as}/#{model.id}"
  end

  version :large do
    process resize_to_fill: [1920, 850]
  end

  version :thumb do
    process resize_to_fill: [384, 170]
  end

  def extension_allowlist
    %w[jpg jpeg png]
  end
end
