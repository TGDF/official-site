module ThemeHelper
  def fa_icon(name)
    content_tag :i, '', class: "fa fa-#{name}"
  end
end
