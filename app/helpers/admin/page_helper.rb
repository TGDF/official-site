# frozen_string_literal: true

module Admin
  module PageHelper
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
  end
end
