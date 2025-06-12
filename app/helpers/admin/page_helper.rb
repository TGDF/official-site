# frozen_string_literal: true

module Admin
  module PageHelper
    def admin_page_header(title, description = nil)
      # TODO: Replace to CoreUI style
      # tag.section(class: 'content-header') do
      #   tag.h1 do
      #     concat title
      #     concat(tag.small(description)) if description.present?
      #   end
      #   # TODO: Add breadcrumb
      # end
    end

    def admin_box(&)
      tag.div(class: "card", &)
    end

    def admin_box_header(title, options = {})
      tag.div(title, class: [ "card-header", options[:class] ].join(" "))
    end

    def admin_box_body(options = {}, &)
      tag.div(class: [ "card-body", options[:class] ].join(" "), &)
    end

    def admin_box_footer(&)
      tag.div(class: "card-footer", &)
    end

    def admin_locale_navtab(options = {})
      admin_navtab_nav do
        I18n.available_locales.each do |locale|
          concat admin_locale_navtab_item(locale.to_s)
        end
      end
    end

    def admin_locale_navtab_item(locale)
      admin_navtab_nav_item(I18n.t("locale.name.#{locale}"),
                            { resource_locale: locale },
                            disable_toggle: true,
                            active: admin_current_resource_locale == locale)
    end
    
    def admin_v2_locale_navtab
      content_tag :div, class: "h-10 items-center justify-center rounded-md p-1 text-muted-foreground grid w-full auto-cols-fr grid-flow-col bg-gray-100 mb-6" do
        I18n.available_locales.each do |locale|
          is_active = locale.to_s == admin_current_resource_locale.to_s
          classes = "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
          classes += is_active ? " bg-white shadow-sm text-gray-900" : " text-gray-600 hover:text-gray-900 hover:bg-gray-50"
          
          concat(link_to(locale.to_s.upcase, url_for(resource_locale: locale), class: classes))
        end
      end
    end
  end
end
