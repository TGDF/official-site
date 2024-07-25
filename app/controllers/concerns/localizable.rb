# frozen_string_literal: true

module Localizable
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
    before_action :rewrite_locale_path
    helper_method :current_locale
  end

  def rewrite_locale_path
    return unless request.path.include?('zh-TW')

    # NOTE: turbolinks-rails didn't rewrite url for now
    redirect_to(url_for(lang: nil))
  rescue ActionController::UrlGenerationError
    redirect_to(root_path(lang: nil))
  end

  def current_locale
    @current_locale ||=
      (I18n.available_locales & [params[:lang]&.to_sym]).first
  end

  private

  def set_locale
    I18n.locale = current_locale || I18n.default_locale
  end
end
