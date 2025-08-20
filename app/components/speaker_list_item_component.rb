# frozen_string_literal: true

class SpeakerListItemComponent < ViewComponent::Base
  with_collection_parameter :speaker

  delegate_missing_to :@speaker

  def initialize(speaker:)
    super()
    @speaker = speaker
  end
end
