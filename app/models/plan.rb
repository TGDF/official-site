# frozen_string_literal: true

class Plan < ApplicationRecord
  acts_as_tenant :site, optional: true, has_global_records: true

  translates :name, :content, :button_label, :button_target

  validates :name, presence: true

  scope :ordered, -> { order(order: :asc) }
end
