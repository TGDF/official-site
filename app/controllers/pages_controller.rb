# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @news = News.published.latest
    @sliders = Slider.all
  end
end
