# frozen_string_literal: true

class ThumbnailUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    "uploads/#{Apartment::Tenant.current}" \
      "/#{model.class.to_s.underscore}" \
      "/#{mounted_as}/#{model.id}"
  end

  version :thumb do
    process resize_to_fill: [570, 355]
  end

  version :large do
    process resize_to_fill: [1920, 420]
  end

  version :medium do
    process resize_to_fill: [770, 420]
  end

  version :small_square do
    process resize_to_fill: [80, 80]
  end

  def extension_allowlist
    %w[jpg jpeg gif png]
  end
end
