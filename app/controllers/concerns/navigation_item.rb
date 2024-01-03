# frozen_string_literal: true

module NavigationItem
  extend ActiveSupport::Concern

  included do
    helper_method :primary_menu_items
    helper_method :secondary_menu_items
  end

  def primary_menu_items # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    [
      { name: t('shared.nav.home'), path: root_path, visible: opened? },
      { name: t('shared.nav.news'), path: news_index_path, visible: opened? },
      { name: t('shared.nav.speakers'), path: speakers_path, visible: opened? },
      { name: t('shared.nav.cfp'), path: agenda_path, visible: cfp_opened? },
      { name: t('shared.nav.agenda'), path: agenda_path, visible: agenda_opened? },
      { name: t('shared.nav.sponsors'), path: sponsors_path, visible: opened? },
      { name: t('shared.nav.indie_spaces'), path: indie_spaces_path, visible: indie_space? },
      { name: t('shared.nav.night_market'), path: night_market_index_path, visible: night_market? },
      { name: t('shared.nav.code_of_conduct'), path: code_of_conduct_path }
    ]
  end

  def secondary_menu_items
    @secondary_menu_items ||= MenuQuery.new.execute
  end

  def closed?
    current_site.cfp_only_mode?
  end

  def agenda_opened?
    opened? && !current_site.cfp_on_agenda_mode?
  end

  def cfp_opened?
    opened? && current_site.cfp_on_agenda_mode?
  end

  def opened?
    !closed?
  end

  def indie_space?
    opened? && !current_site.indie_space_disabled?
  end

  def night_market?
    opened? && current_site.night_market_enabled?
  end
end
