# frozen_string_literal: true

class NewsThumbnailComponent < ViewComponent::Base
  delegate_missing_to :@news

  def initialize(news:, classes: "", size: :medium)
    super
    @news = news
    @size = size
    @classes = classes
  end

  def classes
    [ "relative", @classes ].join(" ")
  end

  def calendar_visible?
    @size != :small_square
  end
end
