# frozen_string_literal: true

module Admin
  module PageHelper
    def admin_current_resource_locale
      ([params[:resource_locale]] & available_locales).first ||
        I18n.default_locale.to_s
    end

    def admin_page_header(title, description = nil)
      content_tag :section, class: 'content-header' do
        content_tag :h1 do
          concat title
          concat content_tag(:small, description) if description.present?
        end
        # TODO: Add breadcrumb
      end
    end

    def admin_box(&block)
      content_tag(:div, class: 'box', &block)
    end

    def admin_box_header(title, options = {})
      content_tag :div, class: ['box-header', options[:class]].join(' ') do
        content_tag :h3, title, class: 'box-title'
      end
    end

    def admin_box_body(options = {}, &block)
      content_tag(:div, class: ['box-body', options[:class]].join(' '), &block)
    end

    def admin_box_footer(&block)
      content_tag(:div, class: 'box-footer', &block)
    end

    def admin_locale_navtab
      admin_navtab_nav do
        available_locales.each do |locale|
          concat admin_locale_navtab_item(locale)
        end
      end
    end

    def admin_locale_navtab_item(locale)
      admin_navtab_nav_item I18n.t("locale.name.#{locale}"),
                            { resource_locale: locale },
                            disable_toggle: true,
                            active: admin_current_resource_locale == locale
    end
  end
end
