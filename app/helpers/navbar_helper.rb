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
end
