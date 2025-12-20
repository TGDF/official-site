# frozen_string_literal: true

class MenuItem < ApplicationRecord
  acts_as_tenant :site, optional: true

  translates :name
  translates :link

  validates :name, :link, :menu_id, presence: true

  enum :menu_id, {
    secondary: "secondary"
  }
end
