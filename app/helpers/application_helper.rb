# frozen_string_literal: true

module ApplicationHelper
  def render_breadcrumb
    return if current_page?(root_path)
    return if current_page?('/')
    return if content_for(:disable_breadcrumb).present?
    render 'shared/breadcrumb'
  end

  def page_title
    [content_for(:page_title), site_name].compact.join(' | ')
  end

  def site_name
    current_site.name || t('site_name')
  end

  def alternate_langs
    capture do
      concat alternate_lang
      I18n.available_locales.each do |locale|
        concat alternate_lang(locale)
      end
    end
  end

  def alternate_lang(lang = nil)
    content_tag(
      :link,
      nil,
      rel: 'alternate',
      hreflang: lang || 'x-default',
      href: url_for(lang: lang, only_path: false)
    )
  end
end
