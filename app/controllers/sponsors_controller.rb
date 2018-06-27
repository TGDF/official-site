# frozen_string_literal: true

class SponsorsController < ApplicationController
  def index
    @sponsor_levels = SponsorLevel.includes(:sponsors)
    @partner_types = PartnerType.includes(:partners)
  end
end
