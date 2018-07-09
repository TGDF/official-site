# frozen_string_literal: true

class GameThumbnailUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    "uploads/#{Apartment::Tenant.current}" \
      "/#{model.class.to_s.underscore}" \
      "/#{mounted_as}/#{model.id}"
  end

  version :thumb do
    process resize_to_fill: [640, 360]
  end

  version :large do
    process resize_to_fill: [1920, 1080]
  end

  def extension_whitelist
    %w[jpg jpeg gif png]
  end
end
