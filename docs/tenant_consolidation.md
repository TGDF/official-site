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

The destructive runs (`consolidate` / `merge`) must not happen near the annual event. The 2026 event ran **2026-07-15 ~ 2026-07-19** and is past, so the window is open; the next freeze is whenever the 2027 dates are set.

**Parallel, out of scope here:** migrating the test suite (RSpec + Cucumber) to Minitest is tracked separately and is demand-driven. It is not a prerequisite for consolidation, but Phase 4 (removing Apartment) does depend on the test harness no longer assuming Apartment — see Phase 4.8.

**Where this stands.** Four no-FK groups are consolidated — `slider`, `block`, `plan`, `menu_item`. Everything with a foreign key, a polymorphic reference, or cross-year uniqueness is still ahead.

> ⚠️ `tenant_consolidation:status` reports a group COMPLETE purely from `Apartment.excluded_models` membership, **not** from actual data presence. Treat `status` as "what the config claims" and `verify[group]` as "what the data shows". `menu_item` is the illustration: it reads ✓ while public *and every tenant table* hold **zero rows**, so that group proved nothing about the tooling.

### Measured state of production

Taken 2026-08-20 across the nine production tenants, read-only. Recorded here because several statements elsewhere in this document were written without it, and because re-measuring needs access to the live environment. The `site_id` and slug rows were re-measured 2026-08-27; the rest still carry the 2026-08-20 figures.

| | Measured | Bearing |
|---|---|---|
| CarrierWave files to move | **1,071** — Speaker 371, Game 214, Sponsor 206, News 126, Attachment 106, Partner 48 | Worst single tenant: 130 game thumbnails |
| `Attachment.record_id` set | **0 in every tenant**; all 106 attachments are `Image` rows carrying only `file` | Critical Constraint #3 |
| Embedded `/uploads/` references | **18** — News.content 15, Block.content 2, Site.indie_space_description 1 | Phase 5.0 |
| Rows with `site_id IS NULL` | **uniform within each schema, never mixed** (2026-08-27): tgdf2018, tgdf, tgdf_2020, tgdf_2021, 2022_TGDF and 2023tgdf carry null on *every* row; 2024/2025/2026tgdf carry *their own* site id on every row; no schema holds a foreign one. Speakers 249/371. Games 214/214, 259 agendas, 155 sponsors, 107 attachments are 2026-08-20 totals, not re-measured. | Critical Constraint #6 |
| Speakers with no slug | **175** (2026-08-27) — tgdf2018, tgdf and tgdf_2021 entirely; tgdf_2020 all but one | `backfill_speaker_slugs` |
| News with no slug | **0** in every tenant (2026-08-27) — nothing to backfill | — |
| Speaker slugs used by more than one year | **39** of 157 distinct (re-confirmed 2026-08-27) | Critical Constraint #5 |
| Partners awaiting the merge | **48** — 2023tgdf 27 / 8 types, 2024tgdf 21 / 6 types | Matches the 2025-12-20 census |
| ActiveStorage rows on unconsolidated models | **0** | `cleanup_attachments` has nothing to do today |
| Slider CarrierWave markers in public | **0 of 34** | `backfill_markers` still required before the Phase 5 gate |
| PostgreSQL | 16.13, 9 tenant schemas + public | Sizing for any migration |

`verify_consolidated_assets` passes today (Slider: tenant CW 32, public AS 34).

### Open questions

Two things this plan asserts but has not settled. **They are open; do not treat any answer below as chosen.** A round of work in 2026-08 answered them one way, changed the schema to match, and was rolled back because those were the user's decisions to make; it is preserved on branch `wip/consolidation-round-full` for reference, not as a starting point. (Speaker slug uniqueness used to be a third question here — it is settled, and the answer lives in Critical Constraint #5.)

**1. What Phase 5.0 resolves an embedded URL against.** The stored URLs address an upload by the id its row had in a tenant schema, and the current spec (match by filename within the site) cannot work — see Phase 5.0 for the production counter-example. Candidates not yet weighed: recording the old id on each consolidated row; a mapping table in the public schema only; or doing the rewrite inside `consolidate[attachment]` while the id map is still in memory, which needs no schema change.

**2. Whether the Dump → Transform → Import path is still warranted** for `agenda` and `attachment`, now that `Attachment.record_id` is known to be unset everywhere — that was its main justification.

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
- **Attachment.record → any model** — NOT safe to remap in place. `record_id` points at a tenant id that changes on consolidation, and the rake task has no cross-group remap (id_maps are per-run). `consolidate[attachment]` **aborts** if any `record_id` is set. Production has **none** (measured 2026-08-20: all 106 attachments are `Image` rows carrying only `file`), so the guard is a tripwire rather than an obstacle — and that removes the main reason the dump/transform/import path was recommended for this group. See Open question 2.

**CKEditor embedded URLs** — every rich-text field (Block/News/Plan/Sponsor/Speaker/Agenda/Game/Site) plus URL inputs (MenuItem.link, Plan.button_target) — together the `RICH_TEXT_FIELDS` set — can embed `<img src="/uploads/image/file/{id}/...">` as inline HTML, not FK relationships. They keep working until S3 cleanup and have no migration-order impact; rewriting is handled in [Phase 5.0](#50-rewrite-ckeditor-embedded-urls-before-deleting-s3-files) and gated by `verify_uploads_unreferenced`.

The set is finite rather than growing: `Admin::ImagesController` — the endpoint CKEditor uploads to — routes its write by the same rule as `upload_field_for`, so it writes CarrierWave only while `Attachment` is still in a tenant schema, and ActiveStorage once the group is consolidated. Consolidating `attachment` is therefore what stops new `/uploads/` references appearing, and only then can the Phase 5.0 rewrite converge.

### Critical Constraints

1. **All migrations use groups** - Even single models are migrated as groups for consistency
2. **Multi-model groups are atomic** - Models with FK relationships are migrated together with automatic ID remapping
3. **Attachment migrates last, and aborts if `record_id` is set** - Polymorphic `record` can reference any model, and the in-place task cannot remap across groups, so `consolidate[attachment]` aborts when any `record_id` is present. Production has none, so this is a tripwire; an attachment that ever does carry one has to be resolved before the run.
4. **Polymorphic safety (News.author)** - News.author references AdminUser (already public, stable ids); no remap needed. Code-guarded: `consolidate[news]` aborts if any `author_type` is a model other than AdminUser (null is fine).
5. **A group's schema change must be *deployed* before its data move; the switch goes out after** - When a group needs a structural change, the migration ships with that group's phase rather than as a loose pre-step — but "same phase" is not "same deploy". A change the consolidation depends on has to be live *before* `consolidate` runs, while the `excluded_models` switch only goes out *after* the move is verified. That is two deploys, and the write freeze spans both (see [Write-Freeze Posture](#write-freeze-posture)).

   Concrete case — **`index_speakers_on_slug`, settled and implemented.** Each year owned its own copy of `speakers`, so `UNIQUE (slug)` expressed per-year uniqueness. One shared public table turns it into a global constraint the data already violates — **39 of 157 distinct speaker slugs are used by more than one year** — and `consolidate[agenda]` would fail on the first of them. `RemoveGlobalUniqueIndexOnSpeakerSlug` drops it and `Speaker.validates_uniqueness_to_tenant :slug` takes over. The cover has to come from the model: `UNIQUE (site_id, slug)` binds nothing while `site_id` is null (Constraint #6), whereas the validation emits `site_id IS NULL AND slug = ?` and does. `news` made the same move in `abf00edb`, and now carries the same validation.

   **Where this sits in the order of operations.** The migration must be deployed before `consolidate[agenda]`, and its `down` only works until that has run — afterwards the colliding slugs share one table and the unique index cannot be rebuilt. `backfill_speaker_slugs` must have run too. FriendlyId's `:scoped` module (`scope: :site`) is the matching change on the *generating* side — today `scope_for_slug_generator` is `base_class.unscoped`, so new slugs are still made globally unique — but it has to wait until **after** the move: `Scoped#should_generate_new_friendly_id?` is true whenever a scope column changes, and `consolidate` assigns `site_id` on every row it writes, so enabling it early would regenerate every migrated slug.

   **Why `validates_uniqueness_to_tenant` and not the plain scoped form.** A new speaker is given a `site_id`, so in a still-null schema it sits in a different scope from the legacy rows and could take a slug one of them already holds — a duplicate `consolidate[agenda]` would then meet once both carry the same `site_id`. While `has_global_records` is on, `validates_uniqueness_to_tenant` also checks a row that *has* a `site_id` against the rows that do not, which closes exactly that gap; `uniqueness: { scope: :site_id }` does not, and a spec pins the difference. Both `Speaker` and `News` use the tenant-aware form for this reason.

6. **`site_id IS NULL` is the normal state of the source data, and the move is what fixes it** - `has_global_records: true` makes those rows visible to every tenant. They are not an edge case: production carries **249 of 371 speakers, all 214 games, 259 agendas, 155 sponsors, 107 attachments** with a null `site_id` — rows predating `acts_as_tenant`. `consolidate` assigns `site_id` on every row it writes, so the public schema comes out with none, which is what makes `has_global_records` safe to drop per group at Step 5. Check the *public* rows after the move, not the tenant source.

   **Read that number per schema, not as a total.** Measured 2026-08-27, each tenant schema is uniform: six carry null on every row, three carry their own site id on every row, and none holds a foreign one. The aggregate reads as "mixed" and it is not — which matters, because a per-site *validation* covers a whole uniform schema (every row shares one scope) and would not cover a mixed one.

   This also decides when a site-scoped unique index starts doing anything. PostgreSQL treats NULLs as distinct, so `UNIQUE (site_id, slug)` constrains nothing while `site_id` is null — which today is most of the table. It becomes a real guarantee only once the rows have moved and been given a `site_id`; making `site_id NOT NULL` afterwards is what would keep it one, and that can only happen once **every** group has moved — the column is still null across nine tenant schemas until then.

   **After Phase 4, `site_id` is the only tenant boundary, and nothing in the database enforces it.** It carries no foreign key and cannot: `sites` lives in public and the tenant tables do not. Today the schema boundary covers for that. `sites.domain` and `sites.tenant_name` also carry only plain indexes, while both `Middleware::FullHostElevators` and `TenantSite#set_tenant` resolve identity through `Site.find_by(domain:)` — a uniqueness gap on the table the whole isolation now hangs from.

## How to Migrate a Group

### 1. Pre-Migration Checklist

- [ ] All models in group have `site_id` column
- [ ] All models in group have `acts_as_tenant :site` configured
- [ ] Models with uploads have `has_migrated_upload` configured
- [ ] Any schema change the move depends on is **deployed**, not merely committed (Critical Constraint #5). For `agenda` that is `RemoveGlobalUniqueIndexOnSpeakerSlug`.
- [ ] For `agenda`: `backfill_speaker_slugs` has been run against production (dry run first), and FriendlyId's `:scoped` module is **not** yet enabled — see Critical Constraint #5
- [ ] Public schema is empty for this group (consolidate aborts otherwise — re-run = rollback + redo; see "Re-runs & Recovery")
- [ ] `consolidation_freeze_<group>` enabled in `/flipper`, and it **stays on until the `excluded_models` deploy is live** (see "Write-Freeze Posture")
- [ ] Not near an event (Timing & Sequencing)
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

1. Deploy the configuration change
2. Verify admin forms use `{field}_attachment`
3. Verify URLs return ActiveStorage paths
4. Monitor for errors
5. **Only now disable `consolidation_freeze_<group>`** — until this deploy is live the app still reads the group from its tenant schema, so an admin edit would land on the abandoned side

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

- Each `PartnerType` becomes a `SponsorLevel` carrying the same name
- An existing `SponsorLevel` of the same name is reused rather than duplicated
- A Partner whose name already exists as a Sponsor is skipped for manual review
- CarrierWave logos are migrated to ActiveStorage

**"Same name" means the whole JSONB value, and the comparison is scoped to one site.** `find_by(site_id:, name:)` compares every locale at once, so `{"en"=>"Gold","zh-TW"=>"黃金級"}` and `{"zh-TW"=>"黃金級"}` are different names. In this data it never bites: the only two tenants holding Partners — 2023tgdf and 2024tgdf — have **zero** SponsorLevels and **zero** Sponsors, so neither the reuse check nor the duplicate check has anything to match against. The merge will create 8 + 6 levels and 27 + 21 sponsors. Keep the exactness in mind only if a future merge runs against a site that already has sponsors.

**Operational step before the merge — 2023tgdf's labels are inconsistent.** That year's `PartnerType` rows pair the English and Chinese names the opposite way round from every other year:

```
2023tgdf:  {"en"=>"Supporting Partners", "zh-TW"=>"協辦單位"}
           {"en"=>"Co-organizers",       "zh-TW"=>"合作單位"}
elsewhere: {"en"=>"Supporting Partners", "zh-TW"=>"合作單位"}
           {"en"=>"Co-organizers",       "zh-TW"=>"協辦單位"}
```

The merge copies names verbatim, so this carries straight into `SponsorLevel`. Fix the two rows in 2023tgdf first, or accept that the archived 2023 page keeps the swap.

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

# Give slug-less speakers their current id as a slug — run BEFORE consolidate[agenda],
# while those ids still mean something (175 rows across four tenants)
bin/rails "tenant_consolidation:backfill_speaker_slugs[true]"   # dry run
bin/rails tenant_consolidation:backfill_speaker_slugs

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

`attach_asset` downloads each CarrierWave object and re-uploads it to ActiveStorage. It runs **after the row transaction commits**, one transaction per asset — not inside the per-tenant transaction, which used to stay open across every download in the group. Production's worst case is 2022_TGDF's 130 game thumbnails in a single tenant; 1,071 files move in total.

| | Rows | Assets |
|---|---|---|
| Transaction | one per tenant, all-or-nothing | one per asset |
| On failure | the tenant's rows roll back | that asset's attachment rolls back; the rows stay committed |
| Recovery | `rollback[group]` then redo | the same — `consolidate` never deletes tenant data |

So a failed run can leave a tenant's rows in public with only some assets attached. That is not a state to patch by hand: `rollback[group]` clears the public rows (purging their attachments) and a clean redo reproduces the result.

Integrity is checked at write time and it still fails loud. The stored blob's byte size is compared against the **authoritative source size read from fog/S3 directly**, captured during collection rather than fetched through the CDN. This rejects an empty download *and* a CDN that answers a missing object with `200` and an HTML error body — which matters because the RDS snapshot does not cover S3, so a silently bad transfer that later passed the Phase 5.5 gate would be unrecoverable. A source whose size cannot be determined raises too: investigate the broken reference rather than migrate it blind.

### Write-Freeze Posture

`consolidate` reads tenant rows, then writes public rows; a write to the tenant schema *during* a run is not captured and is lost on cutover.

**The window is longer than the run.** It closes only when the `excluded_models` change is *deployed* — until then the app still routes that group's queries to the tenant schema, so an admin edit keeps landing on the side that is about to be abandoned. Production deploys wait on a reviewer's approval, so this stretches well past the minutes the data move itself takes:

```
freeze ─┬─ consolidate[group] ─── verify[group] ─── commit the switch ─── deploy ──┬─ unfreeze
        │                                                                          │
        └── writes here land in the tenant schema and are lost ─────────────────────┘
```

**How to hold it.** Each group has a Flipper flag, `consolidation_freeze_<group>` — enable it from `/flipper` before starting and disable it after the deploy is live. While it is on, the admin screens that write that group's data refuse every non-GET request and send the editor back with an explanation; every other screen keeps working, so freezing `sponsor` does not stop anyone editing the agenda. The screen-to-group table is `TenantConsolidation::ADMIN_SCREENS` in `lib/tenant_consolidation.rb`, and a spec asserts it names every group the rake task can move.

The flag does **not** gate the rake task or the Rails console — it is the admin write path only, which is where concurrent edits come from.

Two things to know about it: a refused write answers with a redirect, so while `attachment` is frozen the CKEditor upload endpoint gives the editor a generic upload failure rather than a message it can display; and the check reads a Flipper flag on every admin non-GET request, which is a dependency that path did not previously have.

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

The consolidation is a one-shot, destructive data move whose ultimate safety net is the RDS snapshot. Integration coverage lives in **`spec/lib/tasks/tenant_consolidation_spec.rb`**, which seeds two real tenant schemas (the `sponsor` multi-model group) and drives the actual rake task. It asserts the failure modes most likely to break silently:

| Risk | Assertion after consolidate | Covered |
|------|-----------------------------|---------|
| FK ID remapping | each child points at its OWN tenant's migrated parent (`sponsor.level_id` → the migrated `SponsorLevel` of the same `site_id`), never a stale/cross-tenant id | ✅ |
| Mobility translations | every locale survives — `record[:name]` still has both `en` and `zh-TW` | ✅ |
| Asset transfer | `record.field_attachment.attached?` is true and `blob.byte_size` equals the source size — even for a record invalid under current validations (exercises the `validate: false` attachment persistence) | ✅ |
| Sequence reset | a fresh `create` after consolidation does not raise duplicate-key | ✅ |
| Cross-tenant migration | two tenants both migrate with the correct `site_id` and independent FK maps | ✅ |
| Re-run guard | a second `consolidate` on a non-empty target aborts (no duplicate rows) | ✅ |
| Dry run | `consolidate[group,true]` writes nothing to public | ✅ |
| Partner guard | `consolidate[partner]` aborts (use `merge_partner_to_sponsor`) | ✅ |
| Attachment guard | `consolidate[attachment]` aborts when a `record_id` is set | ✅ |
| News guard | `consolidate[news]` aborts when an `author_type` is not `AdminUser` | ✅ |
| Merge: level + sponsor | `merge_partner_to_sponsor` creates a `SponsorLevel` named after the `PartnerType` (all locales preserved) and a `Sponsor` linked to it | ✅ |
| Merge: reuse level | an existing `SponsorLevel` of the same name is reused, not duplicated | ✅ |
| Merge: dedup | a Partner whose name already exists as a Sponsor is skipped, not duplicated | ✅ |
| Merge: idempotent | a second merge run creates no duplicate sponsors/levels | ✅ |

The merge tests caught a real bug (now fixed): the `SponsorLevel` was created via the Mobility *writer* (`create!(name: hash)`), which nested the locale hash under the current locale (`{"zh-TW"=>{"en"=>…}}`) — corrupting the name and breaking the `find_by(name:)` reuse check. It now writes the raw column, like the Sponsor side.

The speaker-slug cases now have their own coverage: `spec/models/speaker_spec.rb` asserts that two sites may hold the same slug (written, not merely validated — the dropped index lived in the database) and that one site may not, plus the FriendlyId behaviour the migration turns on — `save!(validate: false)` keeps a slug the record was given and *generates* one for a record that has none. `spec/lib/tasks/backfill_speaker_slugs_spec.rb` covers the backfill: id written into a missing slug, empty string treated as missing, existing slug untouched, dry run inert, the `{id}-2` fallback, and the refusal to run once Speaker is public.

Still uncovered (build before running these groups): an end-to-end **agenda** group test (8 models, 2 join tables). Byte-identity is approximated by byte-size; a checksum assertion would be stronger. The **Extract-Class refactor** of the 1089-line rake task (into `TenantConsolidation::*` services for unit-testability) is intentionally deferred until after the migration — restructuring a trusted destructive tool without full unit coverage is higher-risk than the debt.

The spec disables transactional fixtures (it issues CREATE/DROP SCHEMA) and seeds upload-free records for the data path (CarrierWave uses local file storage in test, so the download URL is not HTTP-fetchable — the one asset example stubs the download). It is RSpec today; the same assertions port directly if the suite moves to Minitest.

## Technical Reference

For implementation details (HasMigratedUpload, URL generation, etc.), see:
- [tenant/dual_system.md](tenant/dual_system.md)

## Phase 4: Remove Apartment

> 🛑 **Phase 4 cannot be run in the order written below.** Two dependencies were found
> after this section was drafted. The steps are otherwise accurate, but 4.6 must not be
> executed until they are resolved.
>
> 1. **Removing the gem breaks the Phase 5 gates.** `verify_uploads_unreferenced` and
>    `backfill_markers` reach `Apartment.excluded_models` through
>    `model_already_in_public?`. Those are the only things standing between the plan and
>    an irreversible `aws s3 rm` — and 4.6 deletes what they read.
> 2. **Removing the gem breaks uploads.** `HasMigratedUpload` and `upload_field_for` both
>    decide CarrierWave-vs-ActiveStorage from `Apartment.excluded_models`, and both live
>    until 5.2. Between 4.6 and 5.2 every upload field and every `<field>_url` raises.
>
> Together these make Phase 4 and Phase 5 circular as written. The way out is to collapse
> the dual system to ActiveStorage-only *before* removing the gem — safe once every group
> is consolidated, which Phase 4 already requires — so that 4.6 becomes pure cleanup.
>
> **Also not covered by 4.7's one-line "any `Apartment::Tenant.switch` calls".** Each of
> these needs its own replacement, and the first cannot use the pattern 4.4 gives:
>
> | Where | Why it needs more than a search-and-replace |
> |---|---|
> | `config/routes.rb:68,72` | Routing constraints read `Apartment::Tenant.current`. Routing runs *before* the controller filter that sets `ActsAsTenant.current_tenant`, so the 4.4 pattern evaluates to nil and both branches collapse to the public one. Resolve from `request.host` instead. |
> | `app/controllers/concerns/tenant_site.rb:24,28` | `current_site` and `tenant_site?` are built on `Apartment::Tenant.current`, and `require_tenant_site!` gates the whole admin on them. |
> | `app/models/site.rb:25,31` | `after_create` creates a tenant schema and `before_destroy` drops one. Creating the 2027 site after the gem is gone raises `NameError`. |
> | `config/sitemap.rb:8` | Wraps generation in a tenant switch. |
> | `lib/tasks/upgrade/indie_space.rake:7` | Same. |
> | `lib/tasks/tenant_consolidation.rake` | Uses Apartment throughout; it is also the tool Phase 5 still needs. |


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

> ⚠️ **`tenant_consolidation:rewrite_ckeditor_urls` does not exist.** Defined tasks are: `status`, `consolidate`, `verify`, `rollback`, `reset_sequences`, `cleanup_attachments`, `verify_uploads_unreferenced`, `verify_consolidated_assets`, `migrate_public_assets`, `backfill_markers`, `backfill_speaker_slugs`, `merge_partner_to_sponsor`. How the rewrite resolves a reference is **Open question 1** — settle that before building it.

Rich text embeds an upload as inline HTML, addressed by the id the row had in its tenant schema. Consolidation replaces that id, and deleting `/uploads/` turns every unrewritten embed into a permanent 404. The fields that can hold one are `RICH_TEXT_FIELDS` in the rake task — every rich-text body (Block/News/Plan/Sponsor/Speaker/Agenda/Game/Site) plus the URL inputs an admin can point at an upload (`MenuItem.link`, `Plan.button_target`). That set is exactly what `verify_uploads_unreferenced` scans; keep both in step with the data-editor forms.

**What the stored URLs actually look like** (all 18 in production, measured 2026-08-20):

```
/uploads/image/file/2/screenshot3.jpg                     ← no tenant segment (17 of 18)
/uploads/tgdf/news/thumbnail/14/sgs_tgdf_indie_space.png  ← tenant segment, and NOT an Image
/uploads/<tenant>/<model>/<field>/<id>/<filename>         ← the shape store_dir writes today
```

Two things follow. The tenant segment only arrived with `HasUploaderTenant`, so most embeds predate it and carry nothing that identifies the year. And the target is not always `Image` — one reference points at a `News` thumbnail.

**Matching by filename cannot work.** `Block#4` embeds `/uploads/image/file/92/all_logos_sssa.png` and `Block#6` embeds `.../93/all_logos_sssa.png`: two different files, the same site, the same filename. Only the id separates them — and after Phase 4.5 drops the tenant schemas, nothing records what that id pointed at. Whatever Open question 1 settles on has to be in place *before* the schemas are dropped.

All 18 references do resolve uniquely today on `(model, field, old id, filename)`, so the job is small and finite. Anything that cannot be resolved uniquely must be surfaced for a human rather than guessed: a wrong guess survives as a permanently wrong image.

The set is also finite rather than growing — `Admin::ImagesController` routes its write by the model's schema, so new `/uploads/` references stop appearing once the `attachment` group is consolidated.

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

(`aws s3 rm uploads/` is safe for ActiveStorage blobs: AS stores at the bucket root under random keys, and everything CarrierWave wrote is under `uploads/`. Note the older files sit at `uploads/{model}/{field}/{id}/...` with **no tenant segment** — that only arrived with `HasUploaderTenant` — so a rule written as `uploads/{tenant}/...` would miss most of them. The prefix that matters is `uploads/`.)
