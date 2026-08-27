# frozen_string_literal: true

# A speaker slug is unique to one site, not to the whole table.
#
# Every year owned its own copy of `speakers`, so a `UNIQUE (slug)` index expressed
# per-year uniqueness. Consolidating the years into one public table makes that a
# global constraint instead, which contradicts the tenancy model and is already
# violated by the data: 39 of 157 distinct slugs are used by more than one year.
# `index_speakers_on_site_id_and_slug` carries the uniqueness that still means
# something, and `Speaker.validates_uniqueness_to_tenant :slug` covers the rows the
# index cannot — `site_id` is NULL for six of the nine tenants, and PostgreSQL treats
# NULLs as distinct.
#
# `news` made the same move in abf00edb.
#
# This runs against public and all nine tenant schemas (Apartment.db_migrate_tenants
# defaults to true), so the existence guards keep every schema converging on the same
# state even if one of them never had the index.
#
# `down` only works until `tenant_consolidation:consolidate[agenda]` has run — after
# that the colliding slugs share one table and the unique index cannot be rebuilt.
class RemoveGlobalUniqueIndexOnSpeakerSlug < ActiveRecord::Migration[8.1]
  INDEX = "index_speakers_on_slug"

  def up
    remove_index :speakers, :slug, name: INDEX, if_exists: true
  end

  def down
    add_index :speakers, :slug, unique: true, name: INDEX, if_not_exists: true
  end
end
