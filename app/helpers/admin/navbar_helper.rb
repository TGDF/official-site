# frozen_string_literal: true

module Admin
  module NavbarHelper
    def admin_navbar_site_item(name, host, icon: 'cil-square')
      link_to admin_root_url(host: host), class: 'dropdown-item' do
        concat name
      end
    end
  end
end
