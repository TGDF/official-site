# frozen_string_literal: true

class NavItemComponent < ViewComponent::Base
  include NavbarHelper

  BASE_STYLES = %w[hover:text-red-500].freeze

  def initialize(name:, path:)
    super
    @name = name
    @path = path
  end

  def style
    if current_path_under?(@path)
      ['text-red-500']
    else
      ['text-gray-500']
    end.concat(BASE_STYLES).join(' ')
  end
end
