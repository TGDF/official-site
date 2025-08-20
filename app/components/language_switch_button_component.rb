# frozen_string_literal: true

class LanguageSwitchButtonComponent < ViewComponent::Base
  def initialize(current_locale:)
    super()
    @current_locale = current_locale || :'zh-TW'
  end

  def zh?
    @current_locale == :'zh-TW'
  end

  def target_locale
    @target_locale ||= if zh?
                         :en
    else
                         :'zh-TW'
    end
  end

  def name
    t("locale.name.#{target_locale}")
  end

  def path
    url_for(lang: target_locale)
  end
end
