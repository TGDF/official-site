# frozen_string_literal: true

class NavigationComponent < ViewComponent::Base
  attr_reader :current_site, :current_locale

  def initialize(current_site:, current_locale:)
    super

    @current_site = current_site
    @current_locale = current_locale
  end

  def cfp_only?
    current_site.cfp_only_mode?
  end
end
