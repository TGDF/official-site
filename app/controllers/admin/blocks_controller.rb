# frozen_string_literal: true

module Admin
  class BlocksController < Admin::BaseController
    def index
      @blocks = Block.all
    end

    def new
      @block = Block.new
    end

    def create
      @block = Block.new(permitted_params)
      return redirect_to(admin_blocks_path) if @block.save

      render(:new)
    end

    private

    def permitted_params
      params
        .require(:block)
        .permit(:content, :language, :page, :component_type)
    end
  end
end
