# frozen_string_literal: true

class NavItemComponent < ViewComponent::Base
  include NavbarHelper

  BASE_STYLES = %w[hover:text-red-500].freeze
  BASE_LINK_STYLES = %w[p-2].freeze

  def initialize(name:, path:, target: nil, button: false)
    super
    @name = name
    @path = path
    @target = target
    @button = button
  end

  def button?
    @button == true
  end

  def style
    if current_path_under?(@path)
      ['text-red-500']
    else
      ['text-gray-500']
    end.concat(BASE_STYLES).join(' ')
  end

  def link_style
    if button?
      ['rounded text-white bg-red-500 hover:bg-red-600']
    else
      []
    end.concat(BASE_LINK_STYLES).join(' ')
  end
end
