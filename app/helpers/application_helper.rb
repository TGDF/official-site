# frozen_string_literal: true

module ApplicationHelper
  def render_breadcrumb
    return if current_page?(root_path)
    return if current_page?('/')
    render 'shared/breadcrumb'
  end

  def page_title
    [content_for(:page_title), site_name].compact.join(' | ')
  end

  def site_name
    current_site.name || t('site_name')
  end
end
