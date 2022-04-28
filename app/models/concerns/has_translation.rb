# frozen_string_literal: true

module HasTranslation
  extend ActiveSupport::Concern

  included do
    scope :localized, -> { where(language: I18n.locale) }
  end
end
