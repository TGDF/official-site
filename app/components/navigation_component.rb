# frozen_string_literal: true

class NavigationComponent < ViewComponent::Base
  attr_reader :current_site, :current_locale

  def initialize(current_site:, current_locale:)
    super

    @current_site = current_site
    @current_locale = current_locale
  end

  def closed?
    current_site.cfp_only_mode?
  end

  def agenda_opened?
    opened? && !current_site.cfp_on_agenda_mode?
  end

  def cfp_opened?
    opened? && current_site.cfp_on_agenda_mode?
  end

  def opened?
    !closed?
  end

  def indie_space?
    opened? && !current_site.indie_space_disabled?
  end

  def night_market?
    opened? && current_site.night_market_enabled?
  end
end
