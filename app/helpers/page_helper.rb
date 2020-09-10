# frozen_string_literal: true

module PageHelper
  def banner(path)
    content_for(:page_banner, path)
  end

  def original_url
    url_for(only_path: false)
  end

  def seo_tags
    display_meta_tags(
      site: t('site_name'),
      title: nil,
      description: nil,
      og: seo_og_options,
      reverse: true
    )
  end

  def seo_og_options
    {
      title: :full_title,
      site_name: :site,
      description: :description,
      url: original_url
    }
  end
end
