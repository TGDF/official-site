# frozen_string_literal: true

module Admin
  class SponsorLevelsController < Admin::BaseController
    def index
      @levels = SponsorLevel.all
    end

    def new; end

    def create; end

    def edit; end

    def update; end

    def destroy; end
  end
end
