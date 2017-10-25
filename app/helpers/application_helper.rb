# frozen_string_literal: true

module ApplicationHelper
  def available_locales
    Settings.locales
  end
end
