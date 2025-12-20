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

## Migration Path

### Model Inventory

- **Total models in tenant schemas:** 19 (not counting STI subclasses)
- **Models with file uploads:** 8 (Slider, Partner, Sponsor, Speaker, Game, News, Attachment/Image)
- **Models already in public schema:** Site, AdminUser, ActiveStorage::*

### Recommended Migration Order

ALL migrations use groups for consistent behavior. Multi-model groups must be migrated together due to FK constraints.

**Priority note:** Sponsor is prioritized for upcoming feature development. Partner is deprecated and merges into Sponsor.

| Order | Group | Models | Uploads | Status |
|-------|-------|--------|---------|--------|
| 1 | slider | Slider | image | ⏳ Pending |
| 2 | block | Block | - | ⏳ Pending |
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
FK Constraints (db/schema.rb):
  agenda_times.day_id        → agenda_days.id
  agendas.time_id            → agenda_times.id
  agendas.room_id            → rooms.id
  agendas_speakers.agenda_id → agendas.id
  agendas_speakers.speaker_id → speakers.id  ← MANY-TO-MANY
  partners.type_id           → partner_types.id
  sponsors.level_id          → sponsor_levels.id
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

### Critical Constraints

1. **All migrations use groups** - Even single models are migrated as groups for consistency
2. **Multi-model groups are atomic** - Models with FK relationships are migrated together with automatic ID remapping
3. **Attachment migrates last** - Polymorphic `record` can reference any model; all other models must be in public first
4. **Polymorphic safety** - News.author references AdminUser (already public); no FK constraint

## How to Migrate a Group

### 1. Pre-Migration Checklist

- [ ] All models in group have `site_id` column
- [ ] All models in group have `acts_as_tenant :site` configured
- [ ] Models with uploads have `has_migrated_upload` configured
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

### 4. Verify

```bash
bin/rails "tenant_consolidation:verify[<group>]"
```

### 5. Update Configuration

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

### 6. Deploy and Verify

1. Deploy configuration change
2. Verify admin forms use `{field}_attachment`
3. Verify URLs return ActiveStorage paths
4. Monitor for errors

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

## Critical Constraint

**Data and assets must migrate together.**

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

## Mobility JSONB Translation Handling

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
  acts_as_tenant :site, optional: true, has_global_records: true
end

# After (acts_as_tenant only)
class Speaker < ApplicationRecord
  acts_as_tenant :site
end
```

Remove `optional: true` and `has_global_records: true` if no longer needed.

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

### Post-Removal Verification

- [ ] Application starts without Apartment
- [ ] Tenant isolation works via `acts_as_tenant`
- [ ] All CRUD operations scoped correctly
- [ ] No references to `Apartment::` in codebase

## Phase 5: Remove CarrierWave

After Apartment removal, clean up CarrierWave.

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
