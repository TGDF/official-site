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

    def admin_locale_navtab
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
  end
end
