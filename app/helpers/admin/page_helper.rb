# frozen_string_literal: true

module Admin
  module PageHelper
    def admin_page_header(title, description = nil)
      tag.section(class: 'content-header') do
        tag.h1 do
          concat title
          concat(tag.small(description)) if description.present?
        end
        # TODO: Add breadcrumb
      end
    end

    def admin_box(&block)
      tag.div(class: 'box', &block)
    end

    def admin_box_header(title, options = {})
      tag.div(class: ['box-header', options[:class]].join(' ')) do
        tag.h3(title, class: 'box-title')
      end
    end

    def admin_box_body(options = {}, &block)
      tag.div(class: ['box-body', options[:class]].join(' '), &block)
    end

    def admin_box_footer(&block)
      tag.div(class: 'box-footer', &block)
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
