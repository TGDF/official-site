# frozen_string_literal: true

module Admin
  class BlocksController < Admin::BaseController
    def index
      @blocks = Block.all
    end
  end
end
