# frozen_string_literal: true

class NewsController < ApplicationController
  def index
    @news = News.published.latest
  end

  def show
    @latest = News.published.latest
      .limit(Settings.news.latest.size)
    @news = News.find(params[:id])
  end
end
