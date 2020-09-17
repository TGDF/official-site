# frozen_string_literal: true

module Admin
  module NavtabHelper
    def admin_navtab_box(&block)
      tag.div(class: 'card', &block)
    end

    def admin_navtab_nav(&block)
      tag.ul(class: 'nav nav-tabs', &block)
    end

    def admin_navtab_nav_item(name, path, options = {})
      data ||= {}
      data[:class] = ['nav-link']
      data[:class].push('active') if admin_navtab_active?(path) || options[:active]
      tag.li(class: 'nav-item') do
        link_to name, path, data
      end
    end

    def admin_navtab_active?(path)
      return false unless path.is_a?(Hash)

      request.query_string.include?(URI.encode_www_form(path))
    end
  end
end
