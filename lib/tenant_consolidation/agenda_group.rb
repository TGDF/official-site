# frozen_string_literal: true

module TenantConsolidation
  # The agenda group. Its eight tables point at one another, so they move together,
  # parents first, each foreign key rewritten to its parent's new id:
  #
  #   AgendaDay ◀─ AgendaTime ◀─┐
  #                      Room ◀─ Agenda ◀─ AgendasSpeaker ─▶ Speaker
  #   AgendaTag ◀─ AgendasTagging ─▶ Agenda
  #
  # Tags are one vocabulary across every year, so each distinct tag becomes a single
  # shared AgendaTag. A tagging whose tag or agenda is gone is left out for review;
  # the table never had a database foreign key to stop one. A speaker without a slug
  # is refused: the save would make one from its name, and its /speakers/<id> link
  # would stop resolving — backfill_speaker_slugs runs first. So are two speakers of
  # a site sharing a slug: a null site_id let them past the (site_id, slug) index,
  # which they would break once both carry the site's id.
  module AgendaGroup
    extend Group

    NAME = "agenda"
    MODELS = %w[AgendaDay AgendaTime Room AgendaTag Speaker Agenda AgendasSpeaker AgendasTagging].freeze
    UPLOADS = { "Speaker" => :avatar }.freeze
    SHARED = %w[AgendaTag].freeze

    REFS = {
      "AgendaTime" => { "day_id" => "AgendaDay" },
      "Agenda" => { "time_id" => "AgendaTime", "room_id" => "Room" },
      "AgendasSpeaker" => { "agenda_id" => "Agenda", "speaker_id" => "Speaker" },
      "AgendasTagging" => { "agenda_id" => "Agenda", "agenda_tag_id" => "AgendaTag" }
    }.freeze

    module_function

    def plan(site)
      problems = slug_problems(site)
      raise Plan::Invalid, problems.join("; ") if problems.any?

      Plan.carry(site, MODELS, refs: REFS, skip_dangling: %w[AgendasTagging])
    end

    def slug_problems(site)
      by_slug = site.rows("Speaker").group_by { |row| row.attributes["slug"].presence }
      ids = ->(rows) { rows.map { |row| "##{row.id}" }.join(" ") }
      problems = by_slug.select { |slug, rows| slug && rows.size > 1 }.map do |slug, rows|
        "#{site.tenant_name} Speaker #{ids.call(rows)} share the slug #{slug.inspect}"
      end
      return problems unless by_slug.key?(nil)

      [ "#{site.tenant_name} Speaker #{ids.call(by_slug[nil])} has no slug — run backfill_speaker_slugs before the backup",
        *problems ]
    end

    def census_sections(dump)
      plans = dump.sites.map { |site| plan(site) }
      [
        [ "Taggings whose tag or agenda is gone (left out)",
          plans.flat_map do |plan|
            plan.skipped.fetch("AgendasTagging", []).map do |row|
              "#{plan.site.tenant_name} AgendasTagging##{row.id} → Agenda##{row.attributes['agenda_id']}, " \
                "AgendaTag##{row.attributes['agenda_tag_id']}"
            end
          end ],
        [ "Shared tags, each from the tags of every site with the same name",
          plans.flat_map { |plan| plan.rows_of("AgendaTag").map { |row| [ plan.site.tenant_name, row ] } }
               .group_by { |_tenant_name, row| Plan.shared_key(row) }
               .map do |(_model, attributes), rows|
                 "#{attributes['name'].to_json} ← #{rows.map { |name, row| "#{name}##{row.source.last}" }.join(' ')}"
               end ]
      ]
    end
  end
end
