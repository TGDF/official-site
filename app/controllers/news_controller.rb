# frozen_string_literal: true

class NewsController < ApplicationController
  def index
    @news = News.published.all
  end

  def show
    @news = News.find(params[:id])
  end
end
