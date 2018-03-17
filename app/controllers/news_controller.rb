# frozen_string_literal: true

class NewsController < ApplicationController
  def show
    @news = News.find(params[:id])
    @page_name = @news.title
    @page_bg = @news.thumbnail_url
  end
end
