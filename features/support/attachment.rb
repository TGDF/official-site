# frozen_string_literal: true

module AttachmentHelper
  def uploaded_thumbnail
    Rack::Test::UploadedFile.new(File.open(Rails.root.join('spec/support/brands/logos/TGDF.png')))
  end
end

World(AttachmentHelper)
