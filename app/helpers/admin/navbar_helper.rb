# frozen_string_literal: true

module Admin
  module NavbarHelper
    def admin_navbar_site_item(name, host, icon: 'square')
      tag.li do
        link_to admin_root_url(host: host) do
          concat fa_icon(icon)
          concat ' '
          concat name
        end
      end
    end
  end
end
