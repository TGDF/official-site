# frozen_string_literal: true

module AgendaHelper
  # A time slot may hold sessions shorter than the slot itself, so the slot
  # label alone cannot tell a reader how long a session runs or which of two
  # stacked sessions comes first.
  #
  # Agenda normalizes times to a clock on write, but rows stored before that
  # guard can still carry a date prefix ("2026-07-16 16:30") until they are
  # saved again. The schedule is already grouped by day, so only the clock part
  # is shown either way.
  def agenda_period(agenda)
    return if agenda.begin_at.blank? || agenda.end_at.blank?

    [ agenda.begin_at, agenda.end_at ].map { |time| time.to_s.split.last }.join(" - ")
  end

  def agenda_speaker_links(speakers)
    capture do
      speakers.each_with_index do |speaker, index|
        concat link_to(speaker.name, speaker, class: "text-red-500")
        concat(", ") if speakers.size > index + 1
      end
    end
  end
end
