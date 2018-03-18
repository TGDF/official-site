# frozen_string_literal: true

module PageHelper
  def title(title)
    content_for :page_title, title
  end

  def banner(path)
    content_for :page_banner, path
  end
end
