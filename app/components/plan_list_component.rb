# frozen_string_literal: true

class PlanListComponent < ViewComponent::Base
  def initialize(site:)
    super()
    @site = site
  end

  def section_name
    return :participate if content?
    return :streaming if @site.streaming_enabled?

    :ticket
  end

  def section_content
    return StreamingTrackComponent.with_collection([ 1, 2, 3 ], site: @site) if @site.streaming_enabled?

    PassComponent.with_collection(Settings.ticket.types, site: @site)
  end
end
