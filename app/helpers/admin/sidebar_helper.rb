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
      (URI.decode_www_form(uri.query || "") - request.params.to_a).empty?
    end

    # V2 sidebar item helpers
    def admin_v2_sidebar_section(name)
      content_tag :div, class: "px-2.5 py-1 text-xs font-medium uppercase text-gray-500 tracking-wide" do
        name
      end
    end

    def admin_v2_sidebar_group(name)
      content_tag :div do
        concat content_tag(:h4, name, class: "px-2.5 py-1 text-xs font-medium uppercase text-gray-500 tracking-wide")
        concat content_tag(:ul, capture { yield if block_given? }, class: "space-y-0.5 pl-4")
      end
    end

    def admin_v2_sidebar_item(name, path, icon:)
      is_active = current_admin_path_under?(path)
      link_to path, class: "flex items-center gap-2.5 px-2.5 py-1.5 #{is_active ? 'text-gray-900 bg-gray-50' : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'} rounded-md" do
        concat content_tag(:i, "", class: "fa fa-#{icon} w-4 h-4")
        concat content_tag(:span, name, class: "text-sm")
      end
    end

    def admin_v2_sidebar_treeview(name, icon:, submenu_id: nil)
      submenu_id ||= name.to_s.downcase.gsub(/\s+/, "-").gsub(/[^a-z0-9\-]/, "")

      items = capture { yield if block_given? }
      is_expanded = items.to_str.match?(/class="[^"]*text-gray-900 bg-gray-50[^"]*"/)

      content_tag :div do
        button_content = content_tag(:div, class: "flex items-center gap-2.5") do
          concat content_tag(:i, "", class: "fa fa-#{icon} w-4 h-4")
          concat content_tag(:span, name, class: "text-sm")
        end
        button_content += content_tag(:i, "", class: "fa fa-caret-down w-4 h-4 transition-transform duration-200 #{is_expanded ? 'rotate-180' : ''}")

        concat content_tag(:button, button_content.html_safe,
          class: "flex items-center justify-between w-full px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500",
          "aria-expanded": is_expanded,
          "aria-controls": "#{submenu_id}-submenu",
          "data-sidebar-target": "button",
          "data-action": "click->sidebar#toggle"
        )
        concat content_tag(:div, items,
          id: "#{submenu_id}-submenu",
          class: "ml-6 mt-1 space-y-0.5 transition-all duration-200 overflow-hidden #{is_expanded ? 'max-h-96 opacity-100' : 'max-h-0 opacity-0'}"
        )
      end
    end

    def admin_sidebar_header(name)
      tag.li(name, class: "c-sidebar-nav-title")
    end

    def admin_sidebar_treeview(name, icon:)
      options = { class: "c-sidebar-nav-item c-sidebar-nav-dropdown" }

      items = capture { yield if block_given? }
      options[:class] += " c-show" if items.to_str.match?(/class="[^"]*c-active[^"]*"/)
      tag.li(**options) do
        concat admin_sidebar_link(name, "#", icon:, style: "c-sidebar-nav-dropdown-toggle")
        concat tag.ul(items, class: "c-sidebar-nav-dropdown-items")
      end
    end

    def admin_sidebar_item(name, path, icon:)
      style = "c-sidebar-nav-link"
      style += " c-active" if current_admin_path_under?(path)
      tag.li class: "c-sidebar-nav-item" do
        admin_sidebar_link(name, path, icon:, style:)
      end
    end

    def admin_sidebar_link(name, path, icon:, style: "c-sidebar-nav-link")
      link_to path, class: style do
        concat fa_icon(icon)
        concat " "
        concat name
      end
    end
  end
end
