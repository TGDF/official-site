# frozen_string_literal: true

class PlanComponent < ViewComponent::Base
  with_collection_parameter :plan
  delegate_missing_to :@plan

  def initialize(plan:)
    super
    @plan = plan
  end

  def render?
    name.present?
  end
end
