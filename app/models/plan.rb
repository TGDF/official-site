# frozen_string_literal: true

class Plan < ApplicationRecord
  translates :name, :content, :button_label, :button_target

  alias_attribute :button, :button_label
end
