# frozen_string_literal: true

module ThemeHelper
  def fa_icon(name)
    content_tag :i, '', class: "fa fa-#{name} mr-2"
  end

  def label_with_icon(name, icon)
    capture do
      concat fa_icon(icon)
      concat name
    end
  end
end
