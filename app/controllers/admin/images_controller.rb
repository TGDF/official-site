# frozen_string_literal: true

module Admin
  class ImagesController < Admin::BaseController
    def create
      @image = Image.create(file: image_params)

      render(json: {
               filename: @image.file.filename,
               uploaded: @image.valid?,
               url: @image.file_url
             })
    end

    private

    def image_params
      params.require(:upload)
    end
  end
end
