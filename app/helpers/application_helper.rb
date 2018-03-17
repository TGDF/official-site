# frozen_string_literal: true

module ApplicationHelper
  def available_locales
    Settings.locales
  end

  def render_breadcrumb
    return if current_path_under?(root_path)
    render 'shared/breadcrumb'
  end
end
