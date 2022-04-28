# frozen_string_literal: true

module Admin
  class BlocksController < Admin::BaseController
    before_action :find_block, except: %i[index new create]

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

    def update
      return redirect_to(admin_blocks_path) if @block.update(permitted_params)

      render(:edit)
    end

    private

    def permitted_params
      params
        .require(:block)
        .permit(:content, :language, :page, :component_type)
    end

    def find_block
      @block = Block.find(params[:id])
    end
  end
end
