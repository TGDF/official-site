# frozen_string_literal: true

module Admin
  class SlidersController < Admin::BaseController
    before_action :find_slider, except: %i[index new create]

    def index
      @sliders = Slider.all
    end

    def new
      @slider = Slider.new
    end

    def create
      @slider = Slider.new(permitted_params)
      return redirect_to admin_sliders_path if @slider.save

      render :new
    end

    def edit; end

    def update
      return redirect_to admin_sliders_path if @slider.update(permitted_params)

      render :edit
    end

    def destroy
      @slider.destroy
      redirect_to admin_sliders_path
    end

    private

    def permitted_params
      params
        .require(:slider)
        .permit(:image, :language, :page)
    end

    def find_slider
      @slider = Slider.find(params[:id])
    end
  end
end
