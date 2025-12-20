# frozen_string_literal: true

class NewsController < ApplicationController
  def index
    @news = News.published.latest.with_attached_thumbnail_attachment
  end

  def show
    @latest = News.published.latest
                  .with_attached_thumbnail_attachment
                  .limit(Settings.news.latest.size)
    @news = News.friendly.find(params[:id])
  end
end
