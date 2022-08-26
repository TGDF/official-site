# frozen_string_literal: true

class NewsListItemComponent < ViewComponent::Base
  with_collection_parameter :news

  def initialize(news:)
    super
    @news = news
  end
end
