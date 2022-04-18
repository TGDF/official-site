# frozen_string_literal: true

module AttachmentHelper
  def uploaded_thumbnail(path = 'TGDF.png')
    Rack::Test::UploadedFile.new(File.open(Rails.root.join("spec/support/brands/logos/#{path}")))
  end
end

World(AttachmentHelper)
