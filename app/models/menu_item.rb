# frozen_string_literal: true

class MenuItem < ApplicationRecord
  translates :name
  translates :link

  enum menu_id: {
    secondary: :secondary
  }
end
