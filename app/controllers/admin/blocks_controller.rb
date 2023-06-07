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

      render :new, status: :unprocessable_entity
    end

    def update
      return redirect_to(admin_blocks_path) if @block.update(permitted_params)

      render :edit, status: :unprocessable_entity
    end

    def destroy
      @block.destroy
      redirect_to admin_blocks_path
    end

    private

    def permitted_params
      params
        .require(:block)
        .permit(:content, :language, :page, :order, :component_type)
    end

    def find_block
      @block = Block.find(params[:id])
    end
  end
end
