# frozen_string_literal: true

class NavigationComponent < ViewComponent::Base
  renders_many :primary_items, 'NavItemComponent'
  renders_many :secondary_items, 'NavItemComponent'

  attr_reader :current_site, :current_locale

  def initialize(current_site:, current_locale:)
    super

    @current_site = current_site
    @current_locale = current_locale
  end
end
