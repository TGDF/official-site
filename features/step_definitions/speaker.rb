# frozen_string_literal: true

Given('there are some speakers') do |table|
  table.hashes.each do |speaker|
    speaker[:avatar] = uploaded_thumbnail(speaker[:avatar])
    Speaker.create!(**speaker)
  end
end

Given('{string} has a talk {string} translated from {string} to {string}') do |speaker_name, subject, from, to|
  speaker = Speaker.i18n.find_by!(name: speaker_name)
  Agenda.create!(
    subject:,
    description: 'Talk description',
    language: from,
    translated_language: to,
    translated_type: 'sentence',
    speakers: [ speaker ]
  )
end

Given('{string} has a talk {string} at {string} from {string} to {string}') do |speaker_name, subject, time_label, begin_at, end_at|
  speaker = Speaker.i18n.find_by!(name: speaker_name)
  Agenda.create!(
    subject:,
    description: 'Talk description',
    language: 'ZH',
    time: AgendaTime.find_by!(label: time_label),
    begin_at:,
    end_at:,
    speakers: [ speaker ]
  )
end
