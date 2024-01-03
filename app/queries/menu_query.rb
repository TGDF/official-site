# frozen_string_literal: true

class MenuQuery
  def execute(menu_id)
    items = MenuItem.where(menu_id:).order(:position)
    items.map do |item|
      {
        name: item.name,
        path: item.link,
        visible: item.visible?
      }
    end
  end
end
