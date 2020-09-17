# frozen_string_literal: true

module SVGHelper
  def svg_icon(path, anchor = '', options = {})
    href = asset_pack_path(path)
    href = "#{href}##{anchor}" if anchor.present?

    tag.svg(options) do
      tag.use(nil, 'xlink:href': href)
    end
  end
end
