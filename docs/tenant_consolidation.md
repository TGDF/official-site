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

**Current real progress (verify with `tenant_consolidation:status`):** only the four no-upload, no-FK groups are consolidated — `slider`, `block`, `plan`, `menu_item` (present in `Apartment.excluded_models`). Every remaining group has uploads, FK dependencies, or both — i.e. all the high-risk work is still ahead.

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
FK Constraints (db/schema.rb) — mirrors MIGRATION_GROUPS fk_mappings in the rake task:
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

**Group Dependencies:**

```
Partner Group ──── PartnerType → Partner (FK: type_id)

Sponsor Group ──── SponsorLevel → Sponsor (FK: level_id)

Agenda Group ───── AgendaDay → AgendaTime ─┐
                                           ├→ Agenda ←── Room
                   Speaker ←── AgendasSpeaker ──┘ │
                   AgendaTag ←── AgendasTagging ──┘
```

**Polymorphic References (safe to migrate independently):**
```
News ────────────── references: AdminUser (already in public schema)
Attachment ──────── references: any model (migrate LAST after all others)
```

**CKEditor Embedded URL References (no migration order impact):**
```
Block.content ────── embeds: <img src="/uploads/image/file/{id}/...">
News.content  ────── embeds: <img src="/uploads/image/file/{id}/...">
```

These embedded URLs point to Image (Attachment) records but are NOT FK relationships - they're inline HTML in content fields. The URLs continue working until Phase 5 when S3 files are deleted. URL rewriting is handled in Phase 5.0 before S3 cleanup.

**Production data (2025-12-21):** 11 records with embedded images across tgdf_2021, 2022_TGDF, 2023tgdf tenants.

### Critical Constraints

1. **All migrations use groups** - Even single models are migrated as groups for consistency
2. **Multi-model groups are atomic** - Models with FK relationships are migrated together with automatic ID remapping
3. **Attachment migrates last** - Polymorphic `record` can reference any model; all other models must be in public first
4. **Polymorphic safety** - News.author references AdminUser (already public); no FK constraint
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
- [ ] Consolidation re-run safely on this group in a dry-run / copy (idempotent — see "Idempotency & Resumability")
- [ ] Outside the event freeze window (Timing & Sequencing)
- [ ] RDS snapshot created

### 2. Create RDS Snapshot

```bash
aws rds create-db-snapshot \
  --db-instance-identifier <your-rds-instance> \
  --db-snapshot-identifier <model>-migration-$(date +%Y%m%d)

aws rds wait db-snapshot-available \
  --db-snapshot-identifier <model>-migration-*
```

### 3. Run Consolidation

All migrations use the same command with group name:

```bash
# Dry run first
bin/rails "tenant_consolidation:consolidate[<group>,true]"

# Execute
bin/rails "tenant_consolidation:consolidate[slider]"      # Single model
bin/rails "tenant_consolidation:consolidate[partner]"     # PartnerType + Partner
bin/rails "tenant_consolidation:consolidate[sponsor]"     # SponsorLevel + Sponsor
bin/rails "tenant_consolidation:consolidate[agenda]"      # 8 models together
```

**This is an operational step, not a code change.** The data move runs against the database and is *not* recorded in git — only Steps 5–6 (model edit + `excluded_models`) are committed. See "Recorded Procedure vs Operational Run". Because it is idempotent and re-runnable (see "Idempotency & Resumability"), prefer a **detached one-off ECS task over an interactive `execute-command` session**, so a dropped shell does not abort a long run.

### 4. Verify

```bash
bin/rails "tenant_consolidation:verify[<group>]"
```

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
  PartnerType    # partner group - add together
  Partner        # partner group - add together
  SponsorLevel   # sponsor group - add together
  Sponsor        # sponsor group - add together
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

# Consolidation - all migrations use group names
bin/rails "tenant_consolidation:consolidate[slider]"        # Single model group
bin/rails "tenant_consolidation:consolidate[partner]"       # PartnerType + Partner
bin/rails "tenant_consolidation:consolidate[agenda]"        # All 8 agenda models
bin/rails "tenant_consolidation:consolidate[slider,true]"   # Dry run

# Verification - all verifications use group names
bin/rails "tenant_consolidation:verify[slider]"             # Verify single model group
bin/rails "tenant_consolidation:verify[agenda]"             # Verify all 8 agenda models

# Rollback - all rollbacks use group names
bin/rails "tenant_consolidation:rollback[slider]"           # Rollback single model group
bin/rails "tenant_consolidation:rollback[agenda]"           # Rollback all 8 agenda models

# Reset sequences (for fixing already-migrated models)
bin/rails "tenant_consolidation:reset_sequences[slider]"    # Reset sequences for group

# Cleanup incorrect attachments
bin/rails tenant_consolidation:cleanup_attachments
```

### Available Groups

| Group | Models |
|-------|--------|
| slider | Slider |
| block | Block |
| plan | Plan |
| menu_item | MenuItem |
| game | Game |
| sponsor | SponsorLevel, Sponsor |
| partner | ~~PartnerType, Partner~~ → Use `merge_partner_to_sponsor` task |
| agenda | AgendaDay, AgendaTime, Room, AgendaTag, Speaker, Agenda, AgendasSpeaker, AgendasTagging |
| news | News |
| attachment | Attachment |

## Running on ECS

For `aws ecs execute-command` (interactive shell):

```bash
aws ecs execute-command --cluster <cluster> --task <task-id> \
  --container web --interactive \
  --command '/bin/sh -c "bin/rails tenant_consolidation:consolidate[slider]"'
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

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier <new-instance-name> \
  --db-snapshot-identifier <model>-migration-*
```

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

### 2. PostgreSQL sequences must be reset after consolidation

When records are inserted into the public schema, PostgreSQL auto-generates new IDs using sequences. After consolidation completes, the sequence must be reset to `max(id) + 1` to prevent duplicate key errors on next insert.

**Problem scenario:**
```
1. Consolidation migrates records with IDs 1-10
2. Sequence stops at 5 (last INSERT operation)
3. Next manual INSERT tries to use ID=6 → ERROR: duplicate key
```

**Solution:** The consolidation task now automatically resets sequences after migration completes.

**Manual fix for already-migrated models:**
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

### Recorded Procedure vs Operational Run

A group's migration is **two different things in two different places**:

| Part | Where it lives | Contents |
|------|----------------|----------|
| Data + asset move | Operational — run against the DB, **not in git** | `consolidate[group]` / `merge_partner_to_sponsor` |
| The switch | A git commit | model → plain `acts_as_tenant :site`; add to `excluded_models`; mark doc |

So a "complete" commit (e.g. Slider `4ee2e021`, Block `3afcf1a7`) looks tiny — three lines — because the real work already happened operationally before it. **Order matters:** run + verify the data move first, *then* commit the switch. Committing the switch before the data is in public makes the group's records invisible (Apartment routes a non-excluded model to its tenant schema; an excluded one to public).

### Idempotency & Resumability

The staged, all-at-once run is the main pain point ("分段處理很難遷移"). The fix is to make `consolidate` **safely re-runnable**, so a failed or partial run is recovered by running it again — no manual surgery.

This is cheaper than it looks because **`consolidate` never deletes tenant data** (see Rollback Level 1). The tenant record — with its original id and `file` column — stays available, so the CarrierWave S3 path is always re-derivable from the tenant side. What the task needs to become idempotent:

| Property | What to add |
|----------|-------------|
| No duplicate public rows | Before creating, look up an existing public row for the tenant record by a **natural key** (e.g. `site_id` + slug/name); skip if present |
| No duplicate attachments | Already covered by `already_migrated?` (filename match) — attach only when missing |
| Re-run fills gaps | Iterate all tenant records; for each, ensure (a) the public row exists, (b) its asset is attached |

The data + FK step stays **synchronous and transactional** — its correctness depends on ordering (parents before children) and the in-memory id_map. Do **not** parallelise that step.

### Asset Transfer as a Separate Step (SolidQueue-ready)

Only one part of the migration is a good async candidate: **asset transfer** (download from CarrierWave S3 → attach to ActiveStorage). It is I/O-bound, per-record idempotent, and order-independent (the public row already exists with its final id). The data + FK move is none of these and stays inline.

Design the seam now, defer the queue:

- Factor asset transfer into a step that takes `(site_id, model, tenant_record_id)` and does: find the public row by natural key → derive the CW URL from the still-present tenant record → attach if missing. The existing `attach_asset` / `already_migrated?` helpers are most of this.
- Because the job keys off the **still-present tenant record**, it needs **no extra mapping table** to be lifted into a background job later.
- Run it synchronously for now. If/when SolidQueue is adopted, the same step becomes `perform_later` with batching and retry — no redesign.

**SolidQueue is not installed and not adopted yet** (no `solid_queue` gem; ActiveJob adapter is unset → in-process `:async`, non-durable). Introducing it is gated on evaluating the ECS run model (worker process / service). Treat SolidQueue as the **upgrade path this seam is shaped for**, not a current dependency. Do not route the asset step through the `:async` adapter — it loses jobs on restart, worse than a resumable rake task.

### Why New Data Cannot Use ActiveStorage Before Consolidation

A tempting "stop the bleeding" idea — write *new* records straight to ActiveStorage so the backlog stops growing — does not work here, for the same root cause as Critical Constraint #5:

- `active_storage_attachments` is a **single shared (public) table** keyed by `record_type` + `record_id`.
- A tenant-schema record's `record_id` is only unique **within its schema** — the same id exists in every year's schema. Attaching in that state collides across tenants (exactly what `has_migrated_upload` guards against by forcing CarrierWave for tenant-schema models).
- `record_id` only becomes globally unique **after** consolidation.

The whole read/write path is one binary switch — `Apartment.excluded_models`: in it → public + ActiveStorage (`upload_field_for` returns `{field}_attachment`); not in it → tenant + CarrierWave. There is no half-state. **Consequence:** a group stops accumulating CarrierWave data **automatically** the moment it is consolidated (the four done groups already have). The only lever to lower future migration cost is to **consolidate write-heavy groups sooner** — which is why Sponsor (prioritised for feature work) is a good early target — not a separate "new data → AS" toggle.

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
| Idempotency | running `consolidate` twice produces no duplicate rows or attachments |

The framework is whatever the suite currently uses — this is independent of the separate RSpec/Cucumber → Minitest migration. Prefer one integration test per multi-model group (`partner`, `sponsor`, `agenda`) over unit tests of private helpers.

## Technical Reference

For implementation details (HasMigratedUpload, URL generation, etc.), see:
- [tenant/dual_system.md](tenant/dual_system.md)

## Phase 4: Remove Apartment

After all models are consolidated to public schema, remove the Apartment gem.

### Pre-Removal Checklist

- [ ] All models consolidated (verify with `tenant_consolidation:status`)
- [ ] All models added to `Apartment.excluded_models`
- [ ] Application tested without tenant schema switching
- [ ] RDS snapshot created

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

After Apartment removal, clean up CarrierWave.

### 5.0 Rewrite CKEditor Embedded URLs (BEFORE deleting S3 files)

> ⚠️ **`tenant_consolidation:rewrite_ckeditor_urls` is NOT implemented yet.** The rake file currently defines only: `status`, `consolidate`, `verify`, `rollback`, `reset_sequences`, `cleanup_attachments`, `merge_partner_to_sponsor`. This task must be built before Phase 5.0 can run. The matching strategy below is the spec for that task, not a description of existing code.

CKEditor content fields (Block, News) contain embedded image URLs like `/uploads/image/file/{id}/...`. These must be rewritten to ActiveStorage URLs before deleting S3 uploads.

**Production data (2025-12-21):** 11 records with embedded images
- tgdf_2021/News: 7 records
- 2022_TGDF/Block: 2 records
- 2022_TGDF/News: 1 record
- 2023tgdf/News: 1 record

**Why this is safe to defer to Phase 5:**
- CarrierWave URLs continue working after Attachment migration (S3 files still exist)
- New uploads still use CarrierWave until Phase 5 (`mount_uploader` is still active)
- URL rewriting can be done as a batch operation before S3 deletion

**URL Matching Strategy:**
```ruby
# Extract from embedded URL: /uploads/image/file/5/photo.jpg
# The CarrierWave `file` column is preserved after migration
image = Image.find_by(file: filename, site_id: site.id)
new_url = rails_blob_url(image.file_attachment)
```

**Run rewriting task:**
```bash
bin/rails tenant_consolidation:rewrite_ckeditor_urls
```

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

After verifying all assets migrated:

```bash
# Delete old CarrierWave uploads
aws s3 rm s3://<bucket>/uploads/ --recursive
```
