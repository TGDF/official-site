# frozen_string_literal: true

class SiteFigureUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  def store_dir
    'uploads' \
      "/#{model.class.to_s.underscore}" \
      "/#{mounted_as}/#{model.id}"
  end

  def default_url(*)
    ActionController::Base
      .helpers
      .asset_path('about/about-img.jpg')
  end

  process resize_to_fill: [1920, 1080]

  def extension_allowlist
    %w[png jpg jpeg]
  end

  def filename
    'about.png' if original_filename
  end
end
