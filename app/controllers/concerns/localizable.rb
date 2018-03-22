# frozen_string_literal: true

module Localizable
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
    helper_method :current_locale
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
