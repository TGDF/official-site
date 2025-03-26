# frozen_string_literal: true

class SiteLogoUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    "uploads" \
      "/#{model.class.to_s.underscore}" \
      "/#{mounted_as}/#{model.id}"
  end

  def default_url(*)
    ActionController::Base
      .helpers
      .asset_path("logo.png")
  end

  process resize_to_fit: [ 400, 60 ]

  def extension_allowlist
    %w[png]
  end

  def filename
    "logo.png" if original_filename
  end
end
