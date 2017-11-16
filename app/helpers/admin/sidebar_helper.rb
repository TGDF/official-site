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
      content_tag :li, name, class: 'header'
    end

    def admin_sidebar_treeview(name, icon:, &_block)
      options = { class: 'treeview' }

      items = capture { yield if block_given? }
      if items.to_s.match?(/class="[^"]*active[^"]*"/)
        options[:class] += ' active menu-open'
      end
      content_tag :li, options do
        concat admin_sidebar_link(name, '#', icon: icon)
        concat content_tag(:ul, items, class: 'treeview-menu')
      end
    end

    def admin_sidebar_item(name, path, icon:)
      options = {}
      options[:class] = 'active' if current_admin_path_under?(path)
      content_tag(:li, options) { admin_sidebar_link(name, path, icon: icon) }
    end

    def admin_sidebar_link(name, path, icon:)
      link_to path do
        concat fa_icon(icon)
        concat ' '
        concat name
      end
    end
  end
end
