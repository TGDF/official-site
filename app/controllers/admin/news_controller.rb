# frozen_string_literal: true

module Admin
  class NewsController < Admin::BaseController
    before_action -> { @news = News.find(params[:id]) }, except: :index

    def index
      @news = News.all
    end

    def new; end

    def create; end

    def edit; end

    def update; end

    def destroy
      # TODO: Add policy manager to limit admin or author can delete
      @news.destroy
      redirect_to admin_news_index_path
    end

    def preview; end
  end
end
