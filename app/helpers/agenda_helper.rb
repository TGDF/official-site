# frozen_string_literal: true

module AgendaHelper
  def agenda_speaker_links(speakers)
    capture do
      speakers.each_with_index do |speaker, index|
        concat link_to speaker.name, speaker, class: 'text-pink'
        concat ', ' if speakers.size > index + 1
      end
    end
  end
end
