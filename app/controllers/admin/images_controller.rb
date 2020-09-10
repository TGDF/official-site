# frozen_string_literal: true

module Admin
  class ImagesController < Admin::BaseController
    # TODO: Implement customize upload adapter to support CSRF
    skip_before_action :verify_authenticity_token

    def create
      @image = Image.create(file: params[:upload])

      render(json: {
               filename: @image.file.filename,
               uploaded: @image.valid?,
               url: @image.file_url
             })
    end
  end
end
