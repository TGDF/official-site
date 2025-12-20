# frozen_string_literal: true

class Plan < ApplicationRecord
  acts_as_tenant :site

  translates :name, :content, :button_label, :button_target

  validates :name, presence: true

  scope :ordered, -> { order(order: :asc) }
end
