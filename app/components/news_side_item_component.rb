# frozen_string_literal: true

class NewsSideItemComponent < ViewComponent::Base
  with_collection_parameter :news

  delegate_missing_to :@news

  def initialize(news:)
    super
    @news = news
  end
end
