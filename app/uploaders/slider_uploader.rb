# frozen_string_literal: true

class SliderUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    "uploads/#{Apartment::Tenant.current}" \
      "/#{model.class.to_s.underscore}" \
      "/#{mounted_as}/#{model.id}"
  end

  version :large do
    process resize_to_fill: [1920, 850]
  end

  def extension_whitelist
    %w[jpg jpeg png]
  end
end
