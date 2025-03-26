# frozen_string_literal: true

Site.find_each do |site|
  # Set the host name for URL creation
  SitemapGenerator::Sitemap.default_host = "https://#{site.domain}"
  SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/#{site.domain.split('.').first}"
  SitemapGenerator::Sitemap.create do
    Apartment::Tenant.switch(site.tenant_name) do
      ([ nil ] + I18n.available_locales).each do |locale|
        add root_path(lang: locale)
        add news_index_path(lang: locale)
        add speakers_path(lang: locale)
        add agenda_path(lang: locale)
        add sponsors_path(lang: locale)
        add indie_spaces_path(lang: locale)

        News.find_each do |news|
          add news_path(news, lang: locale), lastmod: news.updated_at
        end

        Speaker.find_each do |speaker|
          add speaker_path(speaker, lang: locale), lastmod: speaker.updated_at
        end
      end
    end
  end
end
