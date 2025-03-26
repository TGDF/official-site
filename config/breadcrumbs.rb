# frozen_string_literal: true

crumb :root do
  link t("shared.nav.home"), root_path
end

crumb :news_index do
  link t("shared.nav.news"), news_index_path
end

crumb :news do |news|
  link news.title, news_path(news)
  parent :news_index
end

crumb :speakers do
  link t("shared.nav.speakers"), speakers_path
end

crumb :speaker do |speaker|
  link speaker.name, speaker_path(speaker)
  parent :speakers
end

crumb :agenda do
  link t("shared.nav.agenda"), agenda_path
end

crumb :sponsors do
  link t("shared.nav.sponsors"), sponsors_path
end
