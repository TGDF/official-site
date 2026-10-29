# frozen_string_literal: true

module TenantConsolidation
  module AgendaGroup
    # A speaker without a slug is reachable only through its id — FriendlyId looks the
    # slug up first and falls back to the primary key. Consolidation replaces every id,
    # and FriendlyId's before_save runs even under `save!(validate: false)`, so such a
    # row lands in public carrying a name-derived slug and its page is gone. Writing the
    # current id into the slug keeps /speakers/{id} resolving to the same person — but
    # only while those ids still mean something, so this runs before the backup.
    module SpeakerSlugs
      Fill = Data.define(:speaker, :slug)

      module_function

      # The slug each slugless speaker of the current tenant schema gets, written
      # unless `dry_run`. `unscoped`: has_global_records would otherwise hide a row
      # carrying another site's id, and that row needs a slug just the same.
      def backfill(dry_run: false)
        taken = Speaker.unscoped.where.not(slug: [ nil, "" ]).pluck(:slug).to_set
        fills = Speaker.unscoped.where(slug: [ nil, "" ]).order(:id).map do |speaker|
          Fill.new(speaker, free_slug(speaker, taken)).tap { |fill| taken << fill.slug }
        end
        # update_column: these rows predate today's validations, the slug is the only
        # thing being corrected, and it must not trigger FriendlyId's callbacks.
        fills.each { |fill| fill.speaker.update_column(:slug, fill.slug) } unless dry_run
        fills
      end

      # The id becomes the slug, unless another speaker in this tenant already uses
      # that string as a slug — /speakers/{that id} already resolves to them, not to
      # this row, so there is no URL here to preserve and any free slug will do.
      def free_slug(speaker, taken)
        base = speaker.id.to_s
        return base unless taken.include?(base)

        suffix = 2
        suffix += 1 while taken.include?("#{base}-#{suffix}")
        "#{base}-#{suffix}"
      end
    end
  end
end
