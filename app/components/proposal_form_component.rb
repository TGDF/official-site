# frozen_string_literal: true

class ProposalFormComponent < ViewComponent::Base
  def initialize(src:, description: nil)
    super
    @src = src
    @description = description
  end

  def description?
    @description.present?
  end
end
