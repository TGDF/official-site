# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @news = News.published
  end
end
