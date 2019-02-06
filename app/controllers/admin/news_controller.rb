# frozen_string_literal: true

module Admin
  class NewsController < Admin::BaseController
    layout 'application', only: :preview
    layout 'admin', except: :preview

    before_action :find_news, except: %i[index new create]

    def index
      @news = News.all
    end

    def new
      @news = News.new
    end

    def create
      Mobility.with_locale(I18n.default_locale) do
        @news = News.new(news_params)
        @news.author = current_admin_user
        return redirect_to admin_news_index_path if @news.save

        render :new
      end
    end

    def edit; end

    def update
      Mobility.with_locale(admin_current_resource_locale) do
        return redirect_to admin_news_index_path if @news.update(news_params)

        render :edit
      end
    end

    def destroy
      # TODO: Add policy manager to limit admin or author can delete
      @news.update(status: :deleted)
      redirect_to admin_news_index_path
    end

    def preview; end

    private

    def find_news
      @news = News.find(params[:id])
    end

    def news_params
      params
        .require(:news)
        .permit(
          :title, :slug, :status, :thumbnail, :remove_thumbnail,
          :content
        )
    end
  end
end
