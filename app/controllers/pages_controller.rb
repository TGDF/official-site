# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @news = News.published.latest
                .limit(Settings.news.latest.size)
    @sliders = Slider.localized.home
    @plans = Plan.ordered
    @partners_and_sponsors = (Partner.all + Sponsor.all)
  end

  def coc; end
end
