# frozen_string_literal: true

module Admin
  module SidebarHelper
    def current_admin_path_under?(path)
      path = url_for(path)
      return false if path == admin_root_path && request.path != path

      uri = URI(path)
      current_admin_path_match?(uri) && current_admin_params_under?(uri)
    end

    def current_admin_path_match?(uri)
      return request.path.start_with?(uri.path) if params[:id].present?

      request.path == uri.path
    end

    def current_admin_params_under?(uri)
      (URI.decode_www_form(uri.query || '') - request.params.to_a).empty?
    end

    def admin_sidebar_header(name)
      tag.li(name, class: 'c-sidebar-nav-title')
    end

    def admin_sidebar_treeview(name, icon:)
      options = { class: 'c-sidebar-nav-item c-sidebar-nav-dropdown' }

      items = capture { yield if block_given? }
      options[:class] += ' c-show' if items.to_str.match?(/class="[^"]*c-active[^"]*"/)
      tag.li(**options) do
        concat admin_sidebar_link(name, '#', icon:, style: 'c-sidebar-nav-dropdown-toggle')
        concat tag.ul(items, class: 'c-sidebar-nav-dropdown-items')
      end
    end

    def admin_sidebar_item(name, path, icon:)
      style = 'c-sidebar-nav-link'
      style += ' c-active' if current_admin_path_under?(path)
      tag.li class: 'c-sidebar-nav-item' do
        admin_sidebar_link(name, path, icon:, style:)
      end
    end

    def admin_sidebar_link(name, path, icon:, style: 'c-sidebar-nav-link')
      link_to path, class: style do
        concat fa_icon(icon)
        concat ' '
        concat name
      end
    end
  end
end
