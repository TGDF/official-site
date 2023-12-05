# frozen_string_literal: true

class BreadcrumbComponent < ViewComponent::Base
  delegate_missing_to :@breadcrumbs

  def initialize(breadcrumbs:)
    super
    @breadcrumbs = breadcrumbs
  end

  def render?
    return false if current_page?('/')
    return false if content_for(:disable_breadcrumb).present?

    any?
  end
end
