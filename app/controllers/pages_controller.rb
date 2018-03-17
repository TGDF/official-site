# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @news = News.published.limit(Settings.news.latest.size)
  end
end
