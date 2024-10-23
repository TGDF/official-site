# frozen_string_literal: true

class GameThumbnailUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include HasUploaderTenant

  def store_dir
    "uploads/#{tenant_name}" \
      "/#{model.class.to_s.underscore}" \
      "/#{mounted_as}/#{model.id}"
  end

  version :thumb do
    process resize_to_fill: [640, 360]
  end

  version :large do
    process resize_to_fill: [1920, 1080]
  end

  def extension_allowlist
    %w[jpg jpeg gif png]
  end
end
