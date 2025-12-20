# CarrierWave to ActiveStorage Migration

This document describes the migration plan from CarrierWave to ActiveStorage for file uploads.

## Overview

The migration uses a **dual-system approach** that allows both CarrierWave and ActiveStorage to coexist during the transition period. The storage system is chosen based on the model's schema location to avoid cross-tenant collisions.

### Key Decisions

- **Schema-based routing** - Models in public schema use ActiveStorage, models in tenant schema use CarrierWave
- **Automatic fallback** - If no ActiveStorage attachment exists, serve from CarrierWave
- **Combined data + asset migration** - Assets must be migrated together with data consolidation (ID remap breaks separate migration)
- **Rails proxy URLs** for serving files (simpler setup)
- **Backward-compatible** `_url` methods with automatic fallback
- **Shared assets** - ActiveStorage uses flat structure without tenant-scoping (simpler than CarrierWave's tenant-specific paths)

### Migration Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 1. Dual-system setup | ✅ Complete | Both systems coexist, schema-based routing |
| 2. Verify fallback works correctly | ✅ Complete | Tested AS → CW fallback logic |
| 3. Schema-based routing | ✅ Complete | Public schema → AS, tenant schema → CW |
| 4. Consolidate data + assets | ⏳ Pending | Migrate tenant data to public with assets |
| 5. Remove CarrierWave | ⏳ Pending | Delete uploaders and legacy code |

## Current State

### Models with Uploads

| Model | Field | Uploader | Variants |
|-------|-------|----------|----------|
| Attachment | file | AttachmentUploader | None |
| Site | logo | SiteLogoUploader | default (400x60) |
| Site | figure | SiteFigureUploader | default (1920x1080) |
| Speaker | avatar | AvatarUploader | v1 (270x270), v1_large (370x370) |
| Partner | logo | LogoUploader | v1 (270x120) |
| Sponsor | logo | LogoUploader | v1 (270x120) |
| Slider | image | SliderUploader | large (1920x850), thumb (384x170) |
| Game | thumbnail | GameThumbnailUploader | thumb (640x360), large (1920x1080) |
| News | thumbnail | ThumbnailUploader | thumb (570x355), large (1920x420), medium (770x420), small_square (80x80) |

### S3 Path Structure

**CarrierWave (tenant-scoped paths):**
```
uploads/{tenant_name}/{model_class}/{field}/{id}/{filename}
uploads/{tenant_name}/{model_class}/{field}/{id}/{version}_{filename}
```

**ActiveStorage (shared flat structure):**
```
{random_key}/{filename}
```

ActiveStorage uses a single flat namespace with unique keys. This is simpler and doesn't require tenant-scoping because:
- Files are referenced by `ActiveStorage::Blob` records in the database
- The blob records are associated with tenant-scoped models via `active_storage_attachments`
- Tenant isolation is maintained at the application level, not the storage level

### Apartment Configuration

ActiveStorage tables are excluded from tenant schemas (stored in public schema):

```ruby
# config/initializers/apartment.rb
config.excluded_models = %w[
  Site
  AdminUser
  MenuItem
  ActiveStorage::Blob
  ActiveStorage::Attachment
  ActiveStorage::VariantRecord
]
```

This ensures all tenants share the same ActiveStorage tables in the public PostgreSQL schema, making assets globally accessible while maintaining tenant association through the linked models.

## Infrastructure Requirements

### Image Processing: MiniMagick to vips

CarrierWave uses **MiniMagick** (ImageMagick wrapper) for image processing. ActiveStorage in Rails 7+ defaults to **vips** for better performance and lower memory usage.

| Library | Used By | Package (Alpine) |
|---------|---------|------------------|
| ImageMagick | CarrierWave (MiniMagick) | `imagemagick` |
| libvips | ActiveStorage (ruby-vips) | `vips` |

**Dockerfile changes required:**

```dockerfile
# Before (CarrierWave only)
RUN apk add --no-cache ... imagemagick imagemagick-jpeg ...

# After (both systems during migration)
RUN apk add --no-cache ... imagemagick imagemagick-jpeg ... vips

# Final (ActiveStorage only)
RUN apk add --no-cache ... vips
```

**Why vips over MiniMagick?**
- 4-8x faster for common operations
- Uses less memory (streaming vs loading entire image)
- Better quality for resizing operations
- Native Rails 7+ default

**Alternative (not recommended):** If you cannot install vips, you can configure ActiveStorage to use MiniMagick:

```ruby
# config/initializers/active_storage.rb
Rails.application.config.active_storage.variant_processor = :mini_magick
```

This is only recommended as a temporary workaround, not a long-term solution.

## Implementation

### New Files

- `app/models/concerns/image_variants.rb` - Variant definitions matching CarrierWave versions
- `app/models/concerns/has_migrated_upload.rb` - Dual-system concern with fallback
- `lib/tasks/active_storage_migration.rake` - Migration and verification tasks

### How It Works

1. Each model includes `HasMigratedUpload` and declares `has_migrated_upload :field`
2. This adds a `{field}_attachment` ActiveStorage attachment alongside the CarrierWave uploader
3. The `{field}_url` method checks model schema location:
   - **Model in tenant schema?** → Always use CarrierWave URL (avoid cross-tenant collision)
   - **Model in public schema + ActiveStorage attached?** → Return ActiveStorage URL
   - **Model in public schema + No attachment?** → Fall back to CarrierWave URL
4. The `{field}_present?` method checks both CarrierWave and ActiveStorage for presence
5. Model validations use `{field}_present?` to accept uploads from either system
6. Admin forms use `upload_field_for` helper to select correct field based on model schema

### URL Generation Decision Table

| Model Schema | ActiveStorage Attached | Result |
|--------------|------------------------|--------|
| Tenant schema (Apartment) | Any | CarrierWave URL (forced fallback) |
| Public schema | Yes | ActiveStorage URL |
| Public schema | No | CarrierWave URL (fallback) |

**Note:** Models still in Apartment tenant schemas always use CarrierWave to avoid cross-tenant attachment collisions. Only models migrated to public schema (added to `Apartment.excluded_models`) can use ActiveStorage.

CarrierWave URL generation delegates directly to the uploader without file existence checks, matching CarrierWave's native `_url` method behavior.

### Feature Flags (Deprecated)

> **Note:** Feature flags are no longer used for storage routing. The system now uses schema-based routing: public schema models use ActiveStorage, tenant schema models use CarrierWave.

#### Current Implementation

```ruby
# HasMigratedUpload#field_url
def #{field}_url(version = nil)
  # Models in tenant schema always use CarrierWave
  return carrierwave_url_for(field, version) if model_in_tenant_schema?

  # Models in public schema use ActiveStorage with CW fallback
  attachment = public_send(attachment_name)
  if attachment.attached?
    active_storage_url_for(attachment, version, variants)
  else
    carrierwave_url_for(field, version)
  end
end
```

#### Admin Form Helper

```ruby
# app/helpers/admin/upload_helper.rb
def upload_field_for(model, field)
  if model_ready_for_active_storage?(model)
    :"#{field}_attachment"  # ActiveStorage
  else
    field                   # CarrierWave
  end
end
```

#### Legacy Flag Tasks (Still Available)

The following rake tasks still exist for backwards compatibility but are not required:
- `setup_flags`, `enable_read`, `disable_read`, `enable_write`, `disable_write`

These can be removed in a future cleanup.

## Migration Playbook

### Phase 1: Current State (Schema-Based Routing)

The system currently uses schema-based routing:

| Model Location | Upload Field | URL Method | Storage |
|----------------|--------------|------------|---------|
| Public schema (Site) | `{field}_attachment` | ActiveStorage | S3 via AS |
| Tenant schema (others) | `{field}` | CarrierWave | S3 via CW |

**Verify current state:**
```bash
bin/rails active_storage_migration:migration_status
```

### Phase 2: Consolidate Data + Assets

When consolidating tenant data to public schema, migrate assets at the same time:

```bash
# This is pseudocode - actual implementation depends on your data migration script
# Key: Get CW URL before import, attach AS after import
```

See "Data & Asset Migration Decision Table" section for detailed strategy.

### Phase 3: Verify Migration

After data consolidation, verify all assets migrated:

```bash
bin/rails active_storage_migration:verify
```

Example output:
```
Migration Verification Report
============================================================

Speaker#avatar: OK
  Total records:      25
  With CarrierWave:   25
  With ActiveStorage: 25
```

### Phase 4: Cleanup Staging

For staging environment, cleanup incorrect attachments:

```bash
bin/rails active_storage_migration:cleanup_attachments
```

### Phase 5: Final Cleanup (After All Models Consolidated)

After all tenant models are in public schema:

1. Remove CarrierWave uploaders and `mount_uploader` calls
2. Remove gems: `carrierwave`, `fog-aws`, `mini_magick` (keep `aws-sdk-s3`)
3. Remove ImageMagick from Dockerfile (keep only `vips`)
4. Simplify `HasMigratedUpload` to remove fallback logic
5. Remove `upload_field_for` helper (always use `{field}_attachment`)
6. Delete old CarrierWave files from S3

## Rollback

The dual-system design means CarrierWave files remain intact as fallback.

### Schema-Based Rollback

Since routing is based on model schema location:

| Issue | Solution |
|-------|----------|
| New uploads failing (public schema) | Check ActiveStorage/S3 config |
| Existing files not showing | CarrierWave fallback handles this automatically |
| Need to force CarrierWave | Move model back to tenant schema (revert consolidation) |

### Cleanup Incorrect Attachments

If cross-tenant collisions occurred on staging:

```bash
bin/rails active_storage_migration:cleanup_attachments
```

This purges all ActiveStorage attachments for tenant-schema models, allowing CarrierWave fallback to serve files correctly.

## Rake Tasks Reference

### Current Tasks

```bash
# Status
bin/rails active_storage_migration:migration_status   # Show schema-based readiness
bin/rails active_storage_migration:status             # Show feature flag status (legacy)

# Migration (only for public-schema models)
bin/rails active_storage_migration:migrate            # Copy files (skips tenant-schema models)
bin/rails active_storage_migration:migrate MODEL=Site # Copy specific model
bin/rails active_storage_migration:verify             # Check migration completeness

# Cleanup
bin/rails active_storage_migration:cleanup_attachments  # Purge attachments for tenant-schema models
```

### Legacy Tasks (Deprecated)

These tasks exist for backwards compatibility but are no longer required:

```bash
bin/rails active_storage_migration:setup_flags    # Create feature flags
bin/rails active_storage_migration:enable_read    # (no effect - routing is schema-based)
bin/rails active_storage_migration:disable_read   # (no effect - routing is schema-based)
bin/rails active_storage_migration:enable_write   # (no effect - routing is schema-based)
bin/rails active_storage_migration:disable_write  # (no effect - routing is schema-based)
```

### Migration Readiness

Models must be migrated to `acts_as_tenant` (in public schema) before ActiveStorage migration:

| Model | Status |
|-------|--------|
| Site | ✅ Ready (in public schema) |
| Attachment, Speaker, Partner, Sponsor, Slider, Game, News | ❌ Waiting (in tenant schema) |

Use `migration_status` task to check current readiness:
```bash
bin/rails active_storage_migration:migration_status
```

### Data & Asset Migration Decision Table

When consolidating tenant data to public schema, both database records AND file assets must be handled correctly.

#### CarrierWave Path Structure

| Model Location | CarrierWave Path |
|----------------|------------------|
| Tenant schema | `uploads/{tenant_name}/{model}/{field}/{id}/{filename}` |
| Public schema (Site) | `uploads/site/{field}/{id}/{filename}` |

#### Critical Constraint: Data and Assets Must Migrate Together

**CarrierWave path depends on `model.id`:**
```
uploads/{tenant_name}/{model}/{field}/{model.id}/{filename}
```

**If IDs are remapped during data consolidation, asset migration will fail:**

| Step | Record | CarrierWave File | Migration Result |
|------|--------|------------------|------------------|
| Before | Speaker ID=5 in tgdf2018 | `uploads/tgdf2018/speaker/avatar/5/photo.jpg` | ✓ |
| After data migration | Speaker ID=100 (remapped) | File still at `.../5/photo.jpg` | - |
| Run AS migration | `uploader.url` uses ID=100 | Looks for `.../100/photo.jpg` | ✗ 404 |

**Conclusion: Two-step migration is NOT possible with ID remapping.**

#### Migration Strategy

Since IDs will be remapped during data consolidation, **get CarrierWave URL before importing data to public schema**.

```ruby
# Pseudocode for combined migration
Site.find_each do |site|
  Apartment::Tenant.switch(site.tenant_name) do
    ActsAsTenant.with_tenant(site) do
      Speaker.find_each do |speaker|
        # 1. Get CarrierWave URL while in tenant schema (original ID valid)
        file_url = speaker.avatar.url

        # 2. Import record to public schema (ID may be remapped)
        new_speaker = import_to_public_schema(speaker, site)

        # 3. Attach asset using the URL we got before import
        if file_url.present?
          new_speaker.avatar_attachment.attach(
            io: URI.open(file_url),
            filename: File.basename(file_url).split("?").first
          )
        end
      end
    end
  end
end
```

**Key:** Get URL → Import data → Attach asset (in that order)

#### CarrierWave Path Resolution

The `HasUploaderTenant` concern determines tenant name for path:

```ruby
# app/uploaders/concerns/has_uploader_tenant.rb
def tenant_name
  ActsAsTenant.current_tenant&.tenant_name || Apartment::Tenant.current
end
```

**This works correctly when:**
- Migration runs within `ActsAsTenant.with_tenant(site)` block
- Record still has original ID (before remapping)

#### Migration Phases

| Phase | Model Location | ActiveStorage | CarrierWave | Action |
|-------|---------------|---------------|-------------|--------|
| 1 | Tenant schema | Skip (collision risk) | Primary | Use CW, forms use CW field |
| 2 | Consolidating | Attach during copy | Download before ID remap | Migrate data + assets together |
| 3 | Public schema | Primary | Fallback only | Use AS, forms use AS field |
| 4 | Cleanup | Primary | Remove files | Delete CW files from S3 |

#### Summary

| Approach | Works? | Notes |
|----------|--------|-------|
| Migrate data first, assets later | ❌ No | ID remap breaks CarrierWave path |
| Migrate assets first, data later | ❌ No | Tenant schema has AS collision risk |
| Migrate data + assets together | ✅ Yes | Download file before ID remap, attach after |

### Future Cleanup

After all models are consolidated to public schema:

1. Remove legacy flag tasks (`setup_flags`, `enable_*`, `disable_*`)
2. Remove `model_in_tenant_schema?` checks (all models in public)
3. Remove `upload_field_for` helper (always use `{field}_attachment`)
4. Remove CarrierWave fallback logic
5. Remove CarrierWave uploaders and gems
