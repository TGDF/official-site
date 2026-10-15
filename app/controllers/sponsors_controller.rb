# frozen_string_literal: true

class SponsorsController < ApplicationController
  def index
    @sponsor_levels = SponsorLevel.includes(sponsors: { logo_attachment_attachment: :blob })
  end
end
