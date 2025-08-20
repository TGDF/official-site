# frozen_string_literal: true

class StreamingTrackComponent < ViewComponent::Base
  with_collection_parameter :track

  def initialize(track:, site:)
    super()
    @track = track
    @site = site
  end
end
