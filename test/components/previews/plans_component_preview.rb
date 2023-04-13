# frozen_string_literal: true

class PlansComponentPreview < ViewComponent::Preview
  def ticket
    render PlansComponent.new(site: Site.new(ticket_buy_link: 'https://example.com'))
  end

  def streaming
    site = Site.new(
      streaming_enabled: true,
      streaming_track_1_url: 'https://example.com',
      streaming_track_2_url: 'https://example.com',
      streaming_track_3_url: 'https://example.com'
    )
    render PlansComponent.new(site:)
  end
end
