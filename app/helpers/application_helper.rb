# frozen_string_literal: true

module ApplicationHelper
  def site_name
    current_site.name || t("site_name")
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
    tag.link(nil, rel: "alternate",
                  hreflang: lang || "x-default",
                  href: url_for(lang:, only_path: false))
  end

  def display_buy_ticket_button?
    current_site.ticket_buy_link.present? && !current_site.streaming_enabled?
  end
end
