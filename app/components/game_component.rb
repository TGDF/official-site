# frozen_string_literal: true

class GameComponent < ViewComponent::Base
  include ViewComponent::Translatable

  delegate :name, :description, :website, :video, to: :@game

  def initialize(game:)
    super
    @game = game
  end

  def thumbnail_image
    link_to_if website.present?,
               image_tag(@game.thumbnail_url(:thumb), class: 'card-img-top'),
               website,
               target: '_blank'
  end

  def link_with_icon(link, label, icon_name)
    link_to_if link.present?, helpers.label_with_icon(label, icon_name), link, target: '_blank' do
      content_tag :div, class: 'virtual-link' do
        helpers.label_with_icon(label, icon_name)
      end
    end
  end
end
