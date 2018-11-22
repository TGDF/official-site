# frozen_string_literal: true

module NavbarHelper
  def current_path_under?(path)
    path = url_for(path)
    return false if path == root_path && request.path != path

    uri = URI(path)
    current_path_match?(uri) && current_params_under?(uri)
  end

  def current_path_match?(uri)
    return request.path.start_with?(uri.path) if params[:id].present?

    request.path == uri.path
  end

  def current_params_under?(uri)
    (URI.decode_www_form(uri.query || '') - request.params.to_a).empty?
  end

  def nav_item(name, path, options = {})
    style = []
    style << 'current' if current_path_under?(path)
    content_tag :li, class: style.join(' ') do
      link_to name, path, options
    end
  end

  def language_toggle_button
    target_language = (current_locale || :'zh-TW') == :'zh-TW' ? :en : :'zh-TW'
    content_tag :div, class: 'language-toggler' do
      link_to t("locale.name.#{target_language}"),
              url_for(lang: target_language)
    end
  end
end
