# Tenant Consolidation

This document describes the migration from Apartment (schema-based multi-tenancy) to acts_as_tenant (column-based multi-tenancy).

## Overview

The migration consolidates tenant data from PostgreSQL schemas to a single public schema, using `site_id` columns for tenant isolation. File assets are migrated from CarrierWave to ActiveStorage during the consolidation.

### Key Decisions

- **Combined data + asset migration** - Assets must be migrated together with data (ID remap breaks separate migration)
- **Schema-based routing** - During migration, storage backend is chosen based on model's schema location
- **RDS snapshots for rollback** - Always create snapshot before migration

### Migration Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 1. Dual-system setup | ✅ Complete | Both CarrierWave and ActiveStorage coexist |
| 2. Schema-based routing | ✅ Complete | Public schema → AS, tenant schema → CW |
| 3. Consolidate models | ⏳ In Progress | Migrate tenant data to public with assets |
| 4. Remove Apartment | ⏳ Pending | Drop tenant schemas, remove gem |
| 5. Remove CarrierWave | ⏳ Pending | Delete uploaders and legacy code |

### Timing & Sequencing

The destructive data runs (`consolidate` / `merge`) must not happen near the annual event. The 2026 event runs **2026-07-15 ~ 2026-07-19**; treat that week plus the surrounding days as a freeze window — no data migration.

| Window | What runs | Risk |
|--------|-----------|------|
| Before the event | Doc polish, schema prep (drop non-site-scoped unique indexes), write consolidation tests, dry-runs against a copy | Low — no production data moves |
| Event freeze (07-15 ~ 07-19) | Nothing | — |
| After the event | Group consolidations in order, then Phase 4 / Phase 5 | High — real data moves |

**Parallel, out of scope here:** migrating the test suite (RSpec + Cucumber) to Minitest is tracked separately and is demand-driven. It is not a prerequisite for consolidation, but Phase 4 (removing Apartment) does depend on the test harness no longer assuming Apartment — see Phase 4.8.

**Current real progress (verify with `tenant_consolidation:status`):** only the four no-FK groups are consolidated — `slider`, `block`, `plan`, `menu_item` (present in `Apartment.excluded_models`). Every remaining group has FK dependencies, polymorphic references, or cross-tenant uniqueness to resolve — i.e. all the high-risk work is still ahead.

> ⚠️ `tenant_consolidation:status` reports a group COMPLETE purely from `Apartment.excluded_models` membership, **not** from actual data presence. If a model is added to `excluded_models` before its data move finishes, status shows ✓ while the public table is empty and records are invisible. Treat `status` as "what the config claims," and `verify[group]` as "what the data shows."

## Migration Path

### Model Inventory

- **Total models in tenant schemas:** 19 (not counting STI subclasses)
- **Models with file uploads:** 7 (Slider, Partner, Sponsor, Speaker, Game, News, Attachment). `Image` is an STI subclass of `Attachment` and shares its `file` upload — it is not a separate upload model.
- **Models already in public schema:** Site, AdminUser, ActiveStorage::*

### Recommended Migration Order

ALL migrations use groups for consistent behavior. Multi-model groups must be migrated together due to FK constraints.

**Priority note:** Sponsor is prioritized for upcoming feature development. Partner is deprecated and merges into Sponsor.

| Order | Group | Models | Uploads | Status |
|-------|-------|--------|---------|--------|
| 1 | slider | Slider | image | ✅ Complete |
| 2 | block | Block | - | ✅ Complete |
| 3 | plan | Plan | - | ✅ Complete |
| 4 | menu_item | MenuItem | - | ✅ Complete |
| 5 | sponsor | SponsorLevel, Sponsor | logo | ⏳ Pending |
| 6 | **partner** | **→ Merge to Sponsor** | **logo** | ⏳ Pending |
| 7 | game | Game (+IndieSpace::Game, NightMarket::Game STI) | thumbnail | ⏳ Pending |
| 8 | agenda | AgendaDay, AgendaTime, Room, AgendaTag, Speaker, Agenda, AgendasSpeaker, AgendasTagging | avatar | ⏳ Pending |
| 9 | news | News | thumbnail | ⏳ Pending |
| 10 | attachment | Attachment (+Image STI) | file | ⏳ Pending |

### Migration Dependencies

**Why groups must migrate together:** When records move from tenant to public schema, they get NEW auto-generated IDs. Foreign keys pointing to old IDs will break.

```
Foreign-key relationships remapped during consolidation (rake MIGRATION_GROUPS
fk_mappings). NOTE: not all are DB-enforced — agendas_taggings.* are app-level
associations with no add_foreign_key in db/schema.rb, but still need remapping:
  agenda_times.day_id            → agenda_days.id
  agendas.time_id                → agenda_times.id
  agendas.room_id                → rooms.id
  agendas_speakers.agenda_id     → agendas.id       ← MANY-TO-MANY
  agendas_speakers.speaker_id    → speakers.id      ← MANY-TO-MANY
  agendas_taggings.agenda_id     → agendas.id       ← MANY-TO-MANY
  agendas_taggings.agenda_tag_id → agenda_tags.id   ← MANY-TO-MANY
  partners.type_id               → partner_types.id
  sponsors.level_id              → sponsor_levels.id
```

**Polymorphic references:**
- **News.author → AdminUser** — `author` is polymorphic; AdminUser is public with stable ids so no remap is needed. This is now **code-guarded**: `consolidate[news]` aborts if any `author_type` is a model other than `AdminUser` (a null author is fine) — the same fail-loud guard as Attachment, so a tenant-model author can no longer migrate with a stale id.
- **Attachment.record → any model** — NOT safe to remap in place. `record_id` points at a tenant id that changes on consolidation, and the rake task has no cross-group remap (id_maps are per-run). `consolidate[attachment]` now **aborts** if any `record_id` is set. In practice `Image` rows set only `file` (record_id null), so this rarely triggers; when it does, migrate attachments via the dump/transform/import path (see "Strategy for High-Risk Groups").

**CKEditor embedded URLs** — every rich-text field (Block/News/Plan/Sponsor/Speaker/Agenda/Game/Site) plus URL inputs (MenuItem.link, Plan.button_target) — together the `RICH_TEXT_FIELDS` set — can embed `<img src="/uploads/image/file/{id}/...">` as inline HTML, not FK relationships. They keep working until S3 cleanup and have no migration-order impact; rewriting is handled in [Phase 5.0](#50-rewrite-ckeditor-embedded-urls-before-deleting-s3-files) and gated by `verify_uploads_unreferenced`.

### Critical Constraints

1. **All migrations use groups** - Even single models are migrated as groups for consistency
2. **Multi-model groups are atomic** - Models with FK relationships are migrated together with automatic ID remapping
3. **Attachment migrates last, and aborts if `record_id` is set** - Polymorphic `record` can reference any model. Migrating last is necessary but NOT sufficient: the in-place task cannot remap `record_id` across groups, so `consolidate[attachment]` aborts when any `record_id` is present. Use the dump/transform/import path for attachments that carry real references.
4. **Polymorphic safety (News.author)** - News.author references AdminUser (already public, stable ids); no remap needed. Code-guarded: `consolidate[news]` aborts if any `author_type` is a model other than AdminUser (null is fine).
5. **Schema changes for a group are bundled into that group's phase (atomic)** - When a group needs a structural change (e.g. dropping an index), the migration is written and committed **in the same change-set** as that group's consolidation switch — never as a loose, easily-forgotten pre-step. This keeps "code is in the state the data move expects" true at every commit.

   Concrete case — **non-site-scoped unique indexes**: per-tenant schemas each held their own copy of a table, so a global `unique` index was safe *within one year*. Once rows from every year share one public table, any unique index **not scoped to `site_id`** collides across tenants. Full `db/schema.rb` scan — the only offender is:
   ```
   index_speakers_on_slug              UNIQUE (slug)            ← MUST be dropped (agenda group)
   index_speakers_on_site_id_and_slug  UNIQUE (site_id, slug)   ← keep (correctly scoped)
   ```
   Without dropping `index_speakers_on_slug`, `consolidate[agenda]` fails with a duplicate-key error the moment two years share a speaker slug. The drop migration ships with the agenda phase. (`news` already uses only the site-scoped composite — no action.)
6. **No leftover global records before removing `has_global_records`** - That option makes `site_id IS NULL` rows visible to every tenant. Before removing it (Step 5 / Phase 4.2), confirm the group has no `site_id IS NULL` rows, or they become invisible under plain `acts_as_tenant`.

## How to Migrate a Group

### 1. Pre-Migration Checklist

- [ ] All models in group have `site_id` column
- [ ] All models in group have `acts_as_tenant :site` configured
- [ ] Models with uploads have `has_migrated_upload` configured
- [ ] Non-site-scoped unique indexes on the group's tables dropped, migration committed with this phase (Critical Constraint #5)
- [ ] No `site_id IS NULL` rows remain for the group (Critical Constraint #6)
- [ ] Public schema is empty for this group (consolidate aborts otherwise — re-run = rollback + redo; see "Re-runs & Recovery")
- [ ] Writes to this group's models are frozen for the duration of the run (see "Write-Freeze Posture")
- [ ] Outside the event freeze window (Timing & Sequencing)
- [ ] RDS snapshot created — record its exact identifier for this run

### 2. Create RDS Snapshot

Pin one exact identifier per run and reuse it for `wait` and any later restore — a `*`
wildcard is invalid for `wait`/`restore` and can match the wrong snapshot.

```bash
SNAP="<group>-migration-$(date +%Y%m%d%H%M)"   # exact, recorded for this run

aws rds create-db-snapshot \
  --db-instance-identifier <your-rds-instance> \
  --db-snapshot-identifier "$SNAP"

aws rds wait db-snapshot-available \
  --db-snapshot-identifier "$SNAP"
```

### 3. Run Consolidation

Dry-run first, then execute with the group name (see [Rake Tasks](#rake-tasks) for the full command list):

```bash
bin/rails "tenant_consolidation:consolidate[<group>,true]"   # dry run
bin/rails "tenant_consolidation:consolidate[<group>]"        # execute
```

Never run `consolidate[partner]` — the partner group is retired and the task aborts; use `merge_partner_to_sponsor` (see [Partner Merge](#partner-merge-to-sponsor)).

**This is an operational step, not a code change.** The data move runs against the database and is *not* recorded in git — only Steps 5–6 (model edit + `excluded_models`) are committed. Prefer a **detached one-off ECS task over an interactive `execute-command` session**, so a dropped shell does not abort a long run. If a run fails partway, recover with rollback + redo (see "Re-runs & Recovery") — the task refuses to resume onto a non-empty target.

### 4. Verify

```bash
bin/rails "tenant_consolidation:verify[<group>]"
```

**What `verify` does and does not prove.** It is essentially a count check. On the consolidation (pre-exclude) branch it asserts `public_count >= tenant_count` per model and prints attachment counts; on the public (post-exclude) branch it asserts attachment counts and prints record counts. It does **not** assert FK integrity or translation values. Those, plus asset byte-size, are enforced *at write time* — an unmappable FK, an asset size mismatch, or a lost translation locale each raises and rolls back. So a green `verify` means "row counts are plausible," not "every association is correct." Consolidation **retains the CarrierWave marker column** (dropped only in Phase 5.1), so the post-exclude attachment check meaningfully compares CW-vs-AS per record. Groups consolidated *before* marker retention (the already-done `slider`) have a null marker — the authoritative coverage for them is `verify_consolidated_assets` run **before Phase 4.5** (it counts the tenant source directly, so it catches an asset that was never attached). `backfill_markers` is a secondary aid that repopulates the marker from a *present* AS attachment so the Phase 5.5 gate can later detect one that goes missing afterward; it cannot, by itself, prove a never-attached asset (don't rely on it alone for slider).

### 5. Update Model

Remove `optional: true` and `has_global_records: true` from migrated models:

```ruby
# Before (during migration)
class Slider < ApplicationRecord
  acts_as_tenant :site, optional: true, has_global_records: true
end

# After (migration complete)
class Slider < ApplicationRecord
  acts_as_tenant :site
end
```

**Per-group, here — not deferred to Phase 4.** This flag is removed as soon as *this* group is consolidated and verified (confirm Critical Constraint #6 first: no `site_id IS NULL` rows remain). The four done groups already have plain `acts_as_tenant :site`. Phase 4.2 is only a final sweep, not a batch removal. This is the entire git-recorded change for a group (see Slider `4ee2e021`, Block `3afcf1a7`).

### 6. Update Configuration

Add migrated models to `Apartment.excluded_models`:

```ruby
# config/initializers/apartment.rb
# TARGET END-STATE, not current config. Add each model only AFTER its group's data
# move is verified — adding a model before its data is in public routes its queries
# to an empty public table. (Live config today: Site, AdminUser, MenuItem, Plan,
# Block, Slider + ActiveStorage::*.)
config.excluded_models = %w[
  Site
  AdminUser
  ActiveStorage::Blob
  ActiveStorage::Attachment
  ActiveStorage::VariantRecord
  # Add after verification:
  Slider         # independent
  Block          # independent
  Plan           # independent
  MenuItem       # independent
  Game           # independent (includes STI variants)
  SponsorLevel   # sponsor group - add together
  Sponsor        # sponsor group - add together
  # NOTE: do NOT add Partner / PartnerType — they are retired via
  # merge_partner_to_sponsor and removed in Phase 5, never consolidated.
  # Adding them would route Partner queries to an empty public table.
  AgendaDay      # agenda group - add all 8 together
  AgendaTime     # agenda group
  Room           # agenda group
  AgendaTag      # agenda group
  Speaker        # agenda group
  Agenda         # agenda group
  AgendasSpeaker # agenda group
  AgendasTagging # agenda group
  News           # independent
  Attachment     # independent (migrate last)
]
```

**Important:** When migrating a group, add ALL models from that group to `excluded_models` together.

### 7. Deploy and Verify

1. Deploy configuration change
2. Verify admin forms use `{field}_attachment`
3. Verify URLs return ActiveStorage paths
4. Monitor for errors

### 8. Update Form-Field Tests (if model has file uploads)

After migration, `upload_field_for` switches the form field from `{field}` to `{field}_attachment` (it keys off `Apartment.excluded_models`). Update the affected tests accordingly. The examples below are Cucumber (the current suite); if the suite has moved to Minitest by then, apply the same field rename there — the assertion is framework-neutral.

```gherkin
# Before (CarrierWave)
And I attach files in the "slider" form
  | field | value    |
  | image | TGDF.png |

# After (ActiveStorage)
And I attach files in the "slider" form
  | field            | value    |
  | image_attachment | TGDF.png |
```

## Partner Merge to Sponsor

Since Partner is deprecated and only Sponsor is actively used, Partners are merged into Sponsors during consolidation.

### Production Data Status (2025-12-20)

| Tenant | Partners | Sponsors |
|--------|----------|----------|
| 2018-2022 | 0 | ✓ (26-33 each) |
| 2023tgdf | 27 (8 types) | 0 |
| 2024tgdf | 21 (6 types) | 0 |
| 2025tgdf | 0 | 23 (8 levels) |

- **No duplicates** - No organization exists in both Partner and Sponsor
- **Total to migrate**: 48 Partners from 2 tenants

### Prerequisites

1. Run Sponsor group consolidation first:
   ```bash
   bin/rails "tenant_consolidation:consolidate[sponsor]"
   ```
2. Add SponsorLevel and Sponsor to `Apartment.excluded_models`

### Check Production Data

Run assessment scripts in Rails console to check Partner usage (see status above):
- [x] Count Partners vs Sponsors per tenant
- [x] Identify duplicate names (same org in both) → None found
- [ ] Export Partner data for backup (optional)

### Run Merge

```bash
# Dry run
bin/rails "tenant_consolidation:merge_partner_to_sponsor[true]"

# Execute
bin/rails "tenant_consolidation:merge_partner_to_sponsor"
```

### Merge Behavior

- Each `PartnerType` becomes a `SponsorLevel` (using same name)
- If `SponsorLevel` with same name exists, Partners are added to it
- Partners with duplicate names (already exists in Sponsor) are SKIPPED for manual review
- CarrierWave logos are migrated to ActiveStorage

### Rollback Limitation (no clean undo)

`merge_partner_to_sponsor` adds Partners **into existing** `Sponsor` / `SponsorLevel` records. There is no dedicated rollback, and **`rollback[sponsor]` is not a substitute** — it deletes *all* Sponsor records in the public schema, including the legitimately consolidated ones, not just the merged-in Partners.

Therefore:
- Run the merge **after** `sponsor` is consolidated and verified, never interleaved.
- The only safe recovery is the Level 3 RDS snapshot restore.
- If a reversible merge is ever required, add a provenance marker (e.g. a `migrated_from_partner_id` column) so merged rows can be selectively removed — not currently implemented.

### Post-Merge

After verification, Partner code can be removed (Phase 5 cleanup).

## Rake Tasks

```bash
# Status - shows all groups and their migration status
bin/rails tenant_consolidation:status

# Consolidation - by group name. NOT partner (aborts; use merge).
# agenda / attachment: prefer the Dump→Transform→Import path — in-place is fragile
# for these (see "Strategy for High-Risk Groups"); run in-place only as a fallback.
bin/rails "tenant_consolidation:consolidate[sponsor]"       # SponsorLevel + Sponsor
bin/rails "tenant_consolidation:consolidate[sponsor,true]"  # Dry run

# Verification - all verifications use group names
bin/rails "tenant_consolidation:verify[slider]"             # Verify single model group
bin/rails "tenant_consolidation:verify[agenda]"             # Verify all 8 agenda models

# Rollback - all rollbacks use group names
bin/rails "tenant_consolidation:rollback[slider]"           # Rollback single model group
bin/rails "tenant_consolidation:rollback[agenda]"           # Rollback all 8 agenda models

# Reset sequences (for fixing already-migrated models)
bin/rails "tenant_consolidation:reset_sequences[slider]"    # Reset sequences for group

# Cleanup attachments — DESTRUCTIVE: purges EVERY ActiveStorage attachment on
# all consolidation models still in tenant schemas, across all sites. Intended to
# clear attachments wrongly created on not-yet-migrated (CarrierWave) models. The
# CarrierWave original is unaffected, so it is recoverable, but scope is broad —
# confirm you mean it before running.
bin/rails tenant_consolidation:cleanup_attachments

# Phase 5 gate — exits non-zero if anything still depends on /uploads/ (run before s3 rm)
bin/rails tenant_consolidation:verify_uploads_unreferenced

# Attach ActiveStorage for already-public models (Site logo/figure) from CarrierWave
bin/rails tenant_consolidation:migrate_public_assets

# Backfill CW marker columns from ActiveStorage for pre-retention groups (e.g. slider)
bin/rails tenant_consolidation:backfill_markers

# Authoritative asset check vs tenant source — run BEFORE Phase 4.5 (DROP SCHEMA)
bin/rails tenant_consolidation:verify_consolidated_assets
```

Group → models is listed once in [Recommended Migration Order](#recommended-migration-order).

## Running on ECS

Prefer a **detached one-off task** (survives a dropped shell) over interactive exec for a real run. Interactive exec is fine for `status` / `verify` / dry-runs:

```bash
aws ecs execute-command --cluster <cluster> --task <task-id> \
  --container web --interactive \
  --command '/bin/sh -c "bin/rails tenant_consolidation:verify[sponsor]"'
```

## Rollback Strategy

### Level 1: Before Configuration Update

```bash
bin/rails "tenant_consolidation:rollback[<group>]"
```

Deletes public schema records for all models in the group (in reverse order for FK safety). Tenant data remains intact.

### Level 2: After Configuration Update

1. Remove all group models from `Apartment.excluded_models`
2. Deploy configuration change
3. Run rollback task

### Level 3: Emergency (Database Restore)

Restore creates a **new** instance from the exact snapshot recorded in Step 2; the app is not recovered until you cut over to it.

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier <new-instance-name> \
  --db-snapshot-identifier "$SNAP"   # the exact id recorded for this run
```

Then complete the cutover (the restore alone does nothing for the running app):
1. Put the app in maintenance mode.
2. Repoint the app's database endpoint (connection config / DNS) to `<new-instance-name>`.
3. Verify, then lift maintenance.

## Critical Constraints — Deep Dives

These expand on the mechanics behind the constraints listed under [Migration Path → Critical Constraints](#critical-constraints); they are not a separate set.

### 1. Data and assets must migrate together

CarrierWave path includes `model.id`:
```
uploads/{tenant_name}/{model}/{field}/{model.id}/{filename}
```

If IDs are remapped during consolidation, asset migration will fail:

| Step | ID | CarrierWave Path | Result |
|------|------|-----------------|--------|
| Before | 5 | `.../5/photo.jpg` | ✓ |
| After remap | 100 | Looks for `.../100/photo.jpg` | ✗ 404 |

**Solution:** The consolidation task gets CarrierWave URL before copying data, then attaches via ActiveStorage after.

### 2. PostgreSQL sequences

Consolidation **does not preserve ids** — `extract_raw_attributes` drops `id`, and `save!` lets PostgreSQL assign a fresh id from the sequence. So the sequence advances correctly on its own and a post-run reset is, in this flow, a **defensive no-op** (it would only matter if a future change started inserting explicit ids). The task runs `reset_sequences_for_models` after a successful run anyway; failures there are warnings, not errors.

A standalone reset for already-migrated models exists if ever needed:
```bash
bin/rails "tenant_consolidation:reset_sequences[group_name]"
```

## Mobility JSONB Translation Handling

**Applies only to models declaring `translates`** (Mobility JSONB backend): Plan, MenuItem, SponsorLevel, Sponsor, PartnerType, Partner, Game, AgendaTag, Speaker, Agenda, News.

**Does NOT apply to `HasTranslation` models** (`include HasTranslation` + a `language` enum): **Block and Slider**. These store one row per language, so each translation is an ordinary record that migrates like any other row — the `language` column just travels with it. The JSONB read/write subtleties below are irrelevant to them. (Both are already consolidated; this note prevents the section being misread when handling the remaining Mobility groups.)

Models with `translates` declarations use Mobility's JSONB backend to store translations:

```ruby
# Column stores all locales in JSONB
name: {"en"=>"In-Person Passes", "zh-TW"=>"實體議程購票"}
```

**Important:** Mobility's plugins intercept both reading AND writing:

```ruby
# READING - attribute_methods plugin
record.attributes  # => {"name"=>"實體議程購票"} (current locale only)
record[:name]      # => {"en"=>"...", "zh-TW"=>"..."} (all locales)

# WRITING - writer plugin
Plan.new(name: {"en"=>"...", "zh-TW"=>"..."})  # Only stores current locale
record[:name] = {"en"=>"...", "zh-TW"=>"..."}  # Stores all locales
```

The consolidation task uses raw column access (`record[column]`) for both reading and writing to preserve all locales. It verifies translations are preserved after each record migration and rolls back the transaction if any locales are lost.

## How Consolidation Works

The consolidation handles the ID remapping problem by migrating data and assets together:

### consolidate (for tenant-schema models)

For models still in tenant schemas that have `site_id` column:

```
1. Switch to tenant schema
2. Get CW URL (uses original record.id) ← Must do FIRST
3. Switch to public schema
4. Create new record (gets new ID)
5. Attach file via ActiveStorage
```

This ensures CarrierWave URLs are captured before IDs are remapped.

Records are written with `save!(validate: false)` — model-level validations (presence, format, app-level uniqueness) are **intentionally skipped** so legacy rows that no longer satisfy current validations still migrate verbatim. Integrity therefore rests on the write-time *raises* (unmappable FK, asset size mismatch, lost translation locale, DB constraints), not on model validations. If you need a validation enforced during migration, add it as an explicit check, not via `validate: true`.

**Recorded vs operational:** the data move (`consolidate` / `merge`) runs against the DB and is **not in git**; only the switch (model → plain `acts_as_tenant :site`, add to `excluded_models`) is committed — which is why a "complete" commit (Slider `4ee2e021`, Block `3afcf1a7`) is tiny. Run and verify the data move *first*, then commit the switch; committing first makes the records invisible (Apartment routes a non-excluded model to its tenant schema).

### Re-runs & Recovery

Idempotency here is **group-level, not row-level**. The current task has no reliable per-record dedup — a row-level resume previously dropped join-table rows and corrupted child FKs (now removed). Instead:

- `consolidate[group]` **aborts if the target public table is non-empty.** A partial/failed run is recovered by `rollback[group]` then re-running clean.
- This is safe and cheap because **`consolidate` never deletes tenant data** (Rollback Level 1) — rollback only clears the public rows, so a clean redo reproduces the result.
- The data + FK step is **synchronous and transactional**, ordered parents-before-children via an in-memory id_map built in one full pass. Do not parallelise it; a full pass is what keeps the id_map complete.
- An **unmappable FK** (a source row whose parent id was never migrated — an orphan) **raises and rolls back** the tenant, rather than persisting a stale tenant id. This matters most for `agendas_taggings`, which has no DB foreign key and would otherwise accept a cross-tenant-wrong id silently. If a run aborts here, inspect/clean the orphaned source row, then redo.

### Asset transfer

`attach_asset` downloads each CarrierWave object and re-uploads to ActiveStorage **inside the per-tenant transaction** (rake `consolidate_group`). For large groups (agenda) this holds a DB transaction open across slow network I/O — a real lock/timeout risk. It **re-raises** (never swallows) and rolls back that tenant's whole group on any failure — intentional all-or-nothing; recover via rollback + redo. Integrity is checked by comparing the stored blob's byte size against the **authoritative source size read from fog/S3 directly** (captured during collection), not via the CDN. This rejects not just empty downloads but a CDN that answers a missing object with `200 + an HTML error body` (the asset host is a CDN). It matters because the only safety net is the RDS snapshot, which does **not** cover S3: a silently-bad transfer that later passes Phase 5.5's `s3 rm` would be unrecoverable. (A source whose size cannot be determined also raises — investigate the broken reference rather than migrate it blind.) Asset transfer is the one I/O-bound, order-independent part that *could* be lifted out of the transaction and run separately; **SolidQueue is not installed** and adopting it is gated on the ECS run-model decision, so this stays inline for now (do not route it through the non-durable `:async` adapter). The dump/transform/import path below makes this separation natural.

### Write-Freeze Posture

`consolidate` reads tenant rows, then writes public rows; a write to the tenant schema *during* a run is not captured and is lost on cutover. Before running a group, **freeze writes to that group's models** (admin maintenance window, or take the relevant admin screens offline). The runbook assumes no concurrent writes to a group while it is being consolidated.

Note: a group stops accumulating CarrierWave data automatically once consolidated — `upload_field_for` flips to `{field}_attachment` the moment the model enters `excluded_models`. The app **does not and must not** write ActiveStorage attachments to a model *before* it is consolidated: `upload_field_for` routes its forms to CarrierWave, and ActiveStorage would be unsafe anyway because `active_storage_attachments` is a shared public table keyed by `record_id`, which is only globally unique after the move (pre-move the same id exists in every tenant schema → cross-tenant ambiguous lookups). Any AS attachment found on a not-yet-consolidated model is therefore a leftover from tooling or an aborted run, which is exactly what `cleanup_attachments` removes. The only lever to shrink the backlog is to consolidate write-heavy groups sooner (e.g. Sponsor).

## Strategy for High-Risk Groups: Dump → Transform → Import

For the remaining complex groups — especially **agenda** (8 models, FK web, cross-tenant slug collisions) and **attachment** (polymorphic `record_id`) — the in-place rake task is fragile: its id_map is per-run/in-memory, so it cannot remap cross-group polymorphic references and cannot resume safely. An **ETL approach is recommended** for these:

1. **Dump** every tenant's rows for the group to a JSON file (raw column values). Raw-column dumping *structurally* preserves Mobility JSONB locales — the locale-loss class of bug disappears. Include each upload record's CarrierWave URL/path.
2. **Transform** offline, in one pass holding all data: build a complete old→new id map across *all* models (so polymorphic `Attachment.record_id` becomes remappable), resolve the Partner→Sponsor merge, detect collisions and duplicate names, and validate before touching the target. This is where problems are eliminated pre-emptively rather than discovered mid-write.
3. **Import** the transformed rows into the empty public schema in dependency order, then run **asset transfer** as a separate keyed step (download CW → attach AS) using the dumped URLs.

Trade-offs vs in-place:

| | In-place rake task | Dump → Transform → Import |
|---|---|---|
| Cross-group polymorphic remap | Impossible (per-run id_map) | Works (global id map) |
| Pre-validation before writes | No | Yes (inspect/validate the transformed dump) |
| Mobility locale safety | Manual (raw-column access) | Structural (JSON dump) |
| Resumability | Group-level rollback + redo | Re-import is a pure function of the dump |
| Cost to build | Already exists (done groups) | New tooling |

Keep the in-place task for what is already done; build the ETL path before running `agenda` and `attachment`. The dump file is also a second backup, independent of the RDS snapshot.

## Testing the Consolidation

The consolidation is a one-shot, destructive data move whose only safety net is an RDS snapshot, and the rake task (`lib/tasks/tenant_consolidation.rake`) currently has **no automated coverage**. (The only related spec is `spec/models/concerns/has_migrated_upload_spec.rb`, which covers URL routing, not the task; the old `active_storage_migration.feature` was deleted when the task was renamed.) Every run today relies on manual dry-runs.

Before running a high-risk group (anything with FKs or uploads), add an integration test that seeds two tenants and asserts the things most likely to break silently:

| Risk | Assertion after consolidate |
|------|-----------------------------|
| FK ID remapping | child rows point at the new parent IDs, not the old ones (e.g. `agenda.time_id` resolves to the migrated `AgendaTime`) |
| Mobility translations | every locale survives — `record[:name]` still has both `en` and `zh-TW` |
| Asset transfer | `record.field_attachment.attached?` is true and the file is byte-identical |
| Sequence reset | a fresh `create` after consolidation does not raise duplicate-key |
| Cross-tenant uniqueness | two tenants with the same speaker slug both migrate (after `index_speakers_on_slug` is dropped) |
| Re-run guard | a second `consolidate` on a non-empty target aborts (no duplicate rows) |
| Partner guard | `consolidate[partner]` aborts and points to `merge_partner_to_sponsor` |
| Attachment guard | `consolidate[attachment]` aborts when a `record_id` is set |

The framework is whatever the suite currently uses — this is independent of the separate RSpec/Cucumber → Minitest migration. Prefer one integration test per multi-model group (`partner`, `sponsor`, `agenda`) over unit tests of private helpers.

## Technical Reference

For implementation details (HasMigratedUpload, URL generation, etc.), see:
- [tenant/dual_system.md](tenant/dual_system.md)

## Phase 4: Remove Apartment

After all models are consolidated to public schema, remove the Apartment gem.

### Pre-Removal Checklist

Phase 4.5 drops the tenant schemas — the only correct source — irreversibly. Gate it on **data evidence**, not config:

- [ ] Every group's data was confirmed by `verify[group]` **at its Step 4 (before exclusion)** — NOT `status`, which only reads `excluded_models`. (Post-exclusion `verify` is non-authoritative: its record check only prints and returns true, and for pre-retention groups its attachment check reads `CW=0`. Instead rely on `verify_consolidated_assets` and spot-check directly: public row counts match, sample records have correct associations + attached files.)
- [ ] All models added to `Apartment.excluded_models`
- [ ] Application tested without tenant schema switching
- [ ] **`verify_consolidated_assets` passes** — authoritative count of tenant CarrierWave assets vs public ActiveStorage attachments. This MUST run now, before 4.5 drops the tenant schemas (the only authoritative "which records had a file" source); the Phase 5.5 gate alone cannot detect an asset that was never attached for a pre-retention group (its marker is null and backfill is AS-derived).
- [ ] RDS snapshot created (exact identifier recorded)

### 4.1 Remove Apartment Middleware

```ruby
# config/initializers/apartment.rb
# Delete this file entirely
```

```ruby
# Remove from middleware stack (if configured elsewhere)
# Rails.application.config.middleware.use(Middleware::FullHostElevators)
```

### 4.2 Remove Apartment from Models

```ruby
# Before (dual-system)
class Speaker < ApplicationRecord
  acts_as_tenant :site, optional: true
end

# After (acts_as_tenant only)
class Speaker < ApplicationRecord
  acts_as_tenant :site
end
```

**Timing:** `optional: true` (and `has_global_records: true`) is removed **per group in Step 5**, not here — by the time Phase 4 runs every group already has plain `acts_as_tenant :site`. This subsection is only a final sweep confirming none were missed.

### 4.3 Update Tenant Switching

```ruby
# Before (Apartment + ActsAsTenant)
Apartment::Tenant.switch(site.tenant_name) do
  ActsAsTenant.with_tenant(site) do
    # ...
  end
end

# After (ActsAsTenant only)
ActsAsTenant.with_tenant(site) do
  # ...
end
```

### 4.4 Update Request Handling

```ruby
# Before: lib/middleware/full_host_elevators.rb
# Switches Apartment schema based on domain

# After: Use ActsAsTenant's built-in controller integration
class ApplicationController < ActionController::Base
  set_current_tenant_through_filter
  before_action :set_tenant

  private

  def set_tenant
    site = Site.find_by(domain: request.host)
    set_current_tenant(site)
  end
end
```

### 4.5 Drop Tenant Schemas

```ruby
# db/migrate/YYYYMMDDHHMMSS_drop_tenant_schemas.rb
class DropTenantSchemas < ActiveRecord::Migration[8.1]
  def up
    Site.find_each do |site|
      execute "DROP SCHEMA IF EXISTS #{site.tenant_name} CASCADE"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

### 4.6 Remove Gem

```ruby
# Gemfile
# Remove:
# gem 'apartment'
# gem 'apartment-activejob' (if used)
```

```bash
bundle remove apartment
```

### 4.7 Cleanup Code

Files to remove:
- `config/initializers/apartment.rb`
- `lib/middleware/full_host_elevators.rb`
- Any `Apartment::Tenant.switch` calls
- `Apartment.excluded_models` references

### 4.8 Update the Test Harness

Removing Apartment breaks the test setup, which currently assumes it. `spec/support/apartment.rb` drops/creates a `main` **Apartment schema** and switches into it before each example (dual Apartment + ActsAsTenant). Before (or with) gem removal:

- Replace the schema create/switch with an `ActsAsTenant.with_tenant` setup against a `main` Site in the public schema.
- Remove the `Apartment::Tenant.switch` / `reset` calls in the suite.
- If the suite has migrated to Minitest by then (separate, demand-driven effort), apply the same change to its equivalent helper instead.

This is the one hard dependency between the Minitest migration and Apartment removal — neither blocks the other, but both touch this harness, so coordinate them.

### Post-Removal Verification

- [ ] Application starts without Apartment
- [ ] Tenant isolation works via `acts_as_tenant`
- [ ] All CRUD operations scoped correctly
- [ ] No references to `Apartment::` in codebase
- [ ] Test harness no longer creates/switches an Apartment schema

## Phase 5: Remove CarrierWave

> 🛑 **NOT EXECUTABLE YET — do not run any Phase 5 step.** Phase 5 ends in the only
> irreversible, non-snapshot-recoverable action in this plan (`aws s3 rm uploads/`).
> It must not be attempted until ALL of these hold:
> 1. `rewrite_ckeditor_urls` is **implemented and tested** (it does not exist yet — see 5.0).
> 2. `verify_consolidated_assets` passed **before Phase 4.5** (authoritative, while tenant data still existed).
> 3. `backfill_markers` has run, and `verify_uploads_unreferenced` exits 0.
> 4. Phase 5 tooling has automated test coverage (none exists today — see "Testing the Consolidation").
>
> Until then Phase 5 is a design/spec, not a runbook. The gate (`verify_uploads_unreferenced`)
> will refuse to pass while embeds remain, so the deletion stays blocked by construction.

After Apartment removal, clean up CarrierWave.

### 5.0 Rewrite CKEditor Embedded URLs (BEFORE deleting S3 files)

> ⚠️ **`tenant_consolidation:rewrite_ckeditor_urls` is NOT implemented yet.** Defined tasks are: `status`, `consolidate`, `verify`, `rollback`, `reset_sequences`, `cleanup_attachments`, `verify_uploads_unreferenced`, `verify_consolidated_assets`, `migrate_public_assets`, `backfill_markers`, `merge_partner_to_sponsor`. The rewrite task must be built before Phase 5.0 can run; the matching strategy below is its spec, not existing code.

CKEditor embeds `/uploads/image/file/{id}/...` image URLs into **every rich-text field**, not just Block/News — also `Plan.content`, `Sponsor.description`, `Speaker.description`, `Agenda.description`, `Game.description`, and `Site.{description, indie_space_description, options}` — plus URL inputs an admin can point at an upload (`MenuItem.link`, `Plan.button_target`). All must be rewritten before S3 deletion. The set is encoded as `RICH_TEXT_FIELDS` in the rake task and is exactly what `verify_uploads_unreferenced` scans — keep both in sync with the data-editor admin forms and link/target inputs.

The rewrite joins on the preserved `file` column (consolidation retains every CW marker column, including `Image#file`, so this key survives the id remap):
```ruby
# Embedded URL /uploads/image/file/5/photo.jpg → match by filename within the site
image = Image.find_by(file: filename, site_id: site.id)
new_url = rails_blob_url(image.file_attachment)
```
Note the residual ambiguity: if two `Image` rows in one site share a filename, the embed cannot be disambiguated — surface those for manual review rather than guessing.

### 5.1 Remove Uploaders

```ruby
# Before
class Slider < ApplicationRecord
  mount_uploader :image, SliderUploader
  has_migrated_upload :image, variants: ImageVariants::SLIDER
end

# After
class Slider < ApplicationRecord
  include HasImageAttachment  # Simplified concern
  has_one_attached :image
end
```

### 5.2 Remove Files

- `app/uploaders/*.rb`
- `app/uploaders/concerns/*.rb`
- `app/models/concerns/has_migrated_upload.rb`
- `app/helpers/admin/upload_helper.rb` (upload_field_for)

### 5.3 Remove Gems

```ruby
# Gemfile - Remove:
# gem 'carrierwave'
# gem 'fog-aws'
# gem 'mini_magick'
```

### 5.4 Update Dockerfile

```dockerfile
# Before (both systems)
RUN apk add --no-cache ... imagemagick imagemagick-jpeg ... vips

# After (ActiveStorage only)
RUN apk add --no-cache ... vips
```

### 5.5 Delete S3 Files

⚠️ **Irreversible and NOT snapshot-recoverable** — the RDS snapshot does not cover S3. Deleting `/uploads/` before Phase 5.0's CKEditor rewrite has run would 404 every embedded image permanently. Gate the deletion on the verification task, which fails unless (a) **no field that can hold a `/uploads/` URL** (Block/News/Plan/Sponsor/Speaker/Agenda/Game/Site rich text + MenuItem.link/Plan.button_target — the full `RICH_TEXT_FIELDS` set) still references one, and (b) every upload record — including the already-public **Site** logo/figure — has its ActiveStorage attachment:

```bash
# Already-public models (Site) are not in any group; migrate their assets explicitly
# (transactional + idempotent — a bad download rolls back, so a re-run retries it):
bin/rails tenant_consolidation:migrate_public_assets

# Backfill markers for any group consolidated before marker retention (e.g. slider),
# so the gate below can verify their attachments too:
bin/rails tenant_consolidation:backfill_markers

# Must exit 0 before deleting. Aborts if any group is not yet consolidated (it scans
# the public schema only), and exits 1 listing whatever still depends on /uploads/.
bin/rails tenant_consolidation:verify_uploads_unreferenced

# Only then:
aws s3 rm s3://<bucket>/uploads/ --recursive
```

(`aws s3 rm uploads/` is safe for ActiveStorage blobs — AS stores at the bucket root with random keys, while CarrierWave lives under `uploads/{tenant}/...`; the two key spaces are disjoint.)
