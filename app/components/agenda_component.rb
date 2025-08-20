# frozen_string_literal: true

class AgendaComponent < ViewComponent::Base
  with_collection_parameter :day

  def initialize(day:, rooms:)
    super()
    @day = day
    @rooms = rooms
  end
end
