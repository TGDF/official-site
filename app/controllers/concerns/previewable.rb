# frozen_string_literal: true

module Previewable
  extend ActiveSupport::Concern

  def preview?
    Flipper.enabled?(:preview)
  end

  def preview
    return unless preview?

    yield
  end

  included do
    helper_method :preview?, :preview
  end
end
