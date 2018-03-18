# frozen_string_literal: true

class NewsController < ApplicationController
  def index
    @news = News.published.all
  end

  def show
    @latest = News.published.latest
    @news = News.find(params[:id])
  end
end
