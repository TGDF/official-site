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

- **Total models in tenant schemas:** 21
- **Models with file uploads:** 8 (Slider, Partner, Sponsor, Speaker, Game, News, Attachment/Image)
- **Models already in public schema:** Site, AdminUser, MenuItem, ActiveStorage::*

### Recommended Migration Order

Each row is a single migration unit. Dependencies listed must be migrated together as a group.

| Order | Model | Includes | Uploads | Complexity | Doc |
|-------|-------|----------|---------|------------|-----|
| 1 | Slider | - | image | Easy | [tenant/slider_migration.md](tenant/slider_migration.md) |
| 2 | Block | - | - | Easy | Pending |
| 3 | Plan | - | - | Easy | Pending |
| 4 | Partner | PartnerType | logo | Easy | Pending |
| 5 | Sponsor | SponsorLevel | logo | Easy | Pending |
| 6 | Game | IndieSpace::Game, NightMarket::Game (STI) | thumbnail | Medium | Pending |
| 7 | Room | - | - | Easy | Pending |
| 8 | AgendaDay | AgendaTime | - | Easy | Pending |
| 9 | AgendaTag | - | - | Easy | Pending |
| 10 | Speaker | - | avatar | Medium | Pending |
| 11 | Agenda | AgendasSpeaker, AgendasTagging | - | Hard | Pending |
| 12 | News | - | thumbnail | Hard | Pending |
| 13 | Attachment | Image (STI) | file | Medium | Pending |

### Migration Dependencies

```
Partner ────────── requires: PartnerType
Sponsor ─────────── requires: SponsorLevel
AgendaDay ───────── includes: AgendaTime
Agenda ──────────── requires: Room, AgendaDay, AgendaTag, Speaker
                    includes: AgendasSpeaker, AgendasTagging
News ────────────── references: AdminUser (polymorphic, already public)
Attachment ──────── references: any model (polymorphic)
```

### Critical Constraints

1. **Migrate dependencies together** - Parent model (e.g., SponsorLevel) must be migrated with child (e.g., Sponsor)
2. **Order matters for Agenda** - Room, AgendaDay, AgendaTag, Speaker must complete before Agenda
3. **Join table ID remapping** - AgendasSpeaker/AgendasTagging foreign keys require special handling
4. **Polymorphic safety** - News.author references AdminUser (already public); Attachment.record may reference any model

## How to Migrate a Model

### 1. Pre-Migration Checklist

- [ ] Model has `site_id` column
- [ ] Model has `acts_as_tenant :site` configured
- [ ] Model has `has_migrated_upload` configured
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

```bash
# Dry run first
bin/rails "tenant_consolidation:consolidate[<Model>,true]"

# Execute
bin/rails "tenant_consolidation:consolidate[<Model>]"
```

### 4. Verify

```bash
bin/rails "tenant_consolidation:verify[<Model>]"
```

### 5. Update Configuration

Add model to `Apartment.excluded_models`:

```ruby
# config/initializers/apartment.rb
config.excluded_models = %w[
  Site
  AdminUser
  MenuItem
  ActiveStorage::Blob
  ActiveStorage::Attachment
  ActiveStorage::VariantRecord
  <Model>  # Add after verification
]
```

### 6. Deploy and Verify

1. Deploy configuration change
2. Verify admin forms use `{field}_attachment`
3. Verify URLs return ActiveStorage paths
4. Monitor for errors

## Rake Tasks

```bash
# Status
bin/rails tenant_consolidation:status

# Consolidation (tenant → public schema)
bin/rails "tenant_consolidation:consolidate[Slider]"
bin/rails "tenant_consolidation:consolidate[Slider,true]"  # dry run

# Storage migration (for models already in public schema or without site_id)
bin/rails "tenant_consolidation:migrate_storage[Site]"

# Verification
bin/rails "tenant_consolidation:verify[Slider]"

# Rollback
bin/rails "tenant_consolidation:rollback[Slider]"

# Cleanup incorrect attachments
bin/rails tenant_consolidation:cleanup_attachments
```

## Running on ECS

For `aws ecs execute-command` (interactive shell):

```bash
aws ecs execute-command --cluster <cluster> --task <task-id> \
  --container web --interactive \
  --command '/bin/sh -c "bin/rails tenant_consolidation:migrate_storage[Site]"'
```

## Rollback Strategy

### Level 1: Before Configuration Update

```bash
bin/rails "tenant_consolidation:rollback[<Model>]"
```

Deletes public schema records. Tenant data remains intact.

### Level 2: After Configuration Update

1. Remove model from `Apartment.excluded_models`
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

## Why Two Tasks?

There are two separate rake tasks because of the ID remapping problem above:

### consolidate (for tenant-schema models)

For models still in tenant schemas that have `site_id` column:

```
1. Switch to tenant schema
2. Get CW URL (uses original record.id) ← Must do FIRST
3. Switch to public schema
4. Create new record (gets new ID)
5. Attach file via ActiveStorage
```

### migrate_storage (for public-schema models)

For models already in public schema OR models without `site_id` (like Site itself):

```
1. Record already in public, ID unchanged
2. Get CW URL (still valid)
3. Attach file via ActiveStorage
```

**Safe for migrate_storage:**
- Models already in `Apartment.excluded_models`
- Models without `site_id` column (like Site itself - inherently safe, no ID remapping)

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
