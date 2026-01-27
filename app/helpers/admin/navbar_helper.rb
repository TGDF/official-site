# frozen_string_literal: true

module Admin
  module NavbarHelper
    def admin_navbar_site_item(site, current: false)
      base_classes = "block px-3 py-2 text-sm rounded-md"
      classes = if current
                  "#{base_classes} bg-blue-50 text-blue-700 font-medium"
      else
                  "#{base_classes} text-gray-700 hover:bg-gray-100"
      end

      link_to site.name, admin_root_url(host: site.domain), class: classes
    end

    def admin_navbar_view_all_sites_link
      link_to t("admin.shared.sidebar.view_all_sites"),
              admin_sites_url(host: Settings.site.default_domain),
              class: "block px-3 py-2 text-sm text-blue-600 hover:text-blue-800 hover:bg-gray-50 rounded-md"
    end
  end
end
