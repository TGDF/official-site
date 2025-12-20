# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @news = News.published.latest
                .with_attached_thumbnail_attachment
                .limit(Settings.news.latest.size)
    @sliders = Slider.localized.home.with_attached_image_attachment
    @plans = Plan.ordered
    @partners_and_sponsors = (
      Partner.with_attached_logo_attachment.to_a +
      Sponsor.with_attached_logo_attachment.to_a
    )
  end

  def coc; end
end
