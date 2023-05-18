# frozen_string_literal: true

class Plan
  class << self
    def create!(**attributes)
      @items ||= []
      @items << new(attributes)
    end

    def all
      @items&.dup || []
    end
  end

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name
  attribute :content
  attribute :button
end
