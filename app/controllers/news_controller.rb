# frozen_string_literal: true

class NewsController < ApplicationController
  def index
    @page_name = I18n.t('news.index.title')
    # TODO: Specify page background
    @news = News.published.all
  end

  def show
    @news = News.find(params[:id])
    @page_name = @news.title
    @page_bg = @news.thumbnail_url
  end
end
