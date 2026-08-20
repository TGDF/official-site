# frozen_string_literal: true

module Admin
  class ImagesController < Admin::BaseController
    def create
      @image = Image.new(file_upload: image_params)
      uploaded = @image.save

      # file_url answers with a CarrierWave URL string or an ActiveStorage attachment,
      # depending on where Attachment currently lives; url_for resolves either into the
      # URL CKEditor embeds.
      render(json: {
               filename: @image.file_filename,
               uploaded: uploaded,
               url: url_for(@image.file_url)
             })
    end

    private

    def image_params
      params.require(:upload)
    end
  end
end
