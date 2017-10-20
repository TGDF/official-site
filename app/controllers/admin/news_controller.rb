# frozen_string_literal: true

module Admin
  class NewsController < Admin::BaseController
    def index
      @news = News.all
    end

    def new; end

    def create; end

    def edit; end

    def update; end

    def destroy; end

    def preview; end
  end
end
