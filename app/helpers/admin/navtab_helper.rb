# frozen_string_literal: true

module Admin
  module NavtabHelper
    def admin_navtab_box(&block)
      content_tag :div, class: 'nav-tabs-custom', &block
    end

    def admin_navtab_nav(&block)
      content_tag :ul, class: 'nav nav-tabs', &block
    end

    def admin_navtab_nav_item(name, path, options = {})
      data = { toggle: 'tab' } unless options[:disable_toggle]
      classes = ['active'] if admin_navtab_active?(path) || options[:active]
      content_tag :li, class: (classes || []).join(' ') do
        link_to name, path, data || {}
      end
    end

    def admin_navtab_active?(path)
      return false unless path.is_a?(Hash)

      request.query_string.include? URI.encode_www_form(path)
    end
  end
end
