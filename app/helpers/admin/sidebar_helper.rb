# frozen_string_literal: true

module Admin
  module SidebarHelper
    def admin_sidebar_header(name)
      content_tag :li, name, class: 'header'
    end

    def admin_sidebar_treeview(name, icon:, &_block)
      content_tag :li, class: 'treeview' do
        concat admin_sidebar_link(name, '#', icon: icon)
        concat content_tag(:ul, class: 'treeview-menu') { yield }
      end
    end

    def admin_sidebar_item(name, path, icon:)
      content_tag(:li) { admin_sidebar_link(name, path, icon: icon) }
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
