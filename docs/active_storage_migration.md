# CarrierWave to ActiveStorage Migration

This document describes the migration plan from CarrierWave to ActiveStorage for file uploads.

## Overview

The migration uses a **phased dual-system approach** that allows both CarrierWave and ActiveStorage to coexist during the transition period. This ensures zero downtime and easy rollback.

### Key Decisions

- **Copy files** to new ActiveStorage paths (originals kept for 1 year)
- **Rails proxy URLs** for serving files (simpler setup)
- **Feature flags** control read/write behavior (disabled by default)
- **Backward-compatible** `_url` methods with automatic fallback
- **Shared assets** - ActiveStorage uses flat structure without tenant-scoping (simpler than CarrierWave's tenant-specific paths)

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
3. The `{field}_url` method checks the `active_storage_read` feature flag:
   - **Disabled (default)**: Returns CarrierWave URL (or default_url if no file)
   - **Enabled**: Returns ActiveStorage URL if attached, otherwise falls back to CarrierWave
4. The `{field}_present?` method checks both CarrierWave and ActiveStorage for presence
5. Model validations use `{field}_present?` to accept uploads from either system

### URL Generation Decision Table

| ActiveStorage Attached | Flag Enabled | Result |
|------------------------|--------------|--------|
| No | `read` disabled | CarrierWave URL |
| No | `read` enabled | CarrierWave URL (fallback) |
| Yes | `read` disabled | CarrierWave URL |
| Yes | `read` enabled | ActiveStorage URL |
| Yes | `write` enabled | ActiveStorage URL |

**Note:** CarrierWave URL generation delegates directly to the uploader without file existence checks, matching CarrierWave's native `_url` method behavior.

### Test Cases

#### URL Generation Tests

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-001 | CarrierWave file exists, both flags disabled | CarrierWave URL | ✅ Covered |
| TC-002 | CarrierWave file exists, version requested, flags disabled | CarrierWave version URL | ✅ Covered |
| TC-003 | ActiveStorage attached, read flag enabled | ActiveStorage URL | ✅ Covered |
| TC-004 | ActiveStorage attached, version requested, read flag enabled | ActiveStorage variant URL | ✅ Covered |
| TC-005 | No ActiveStorage, read flag enabled | CarrierWave URL (fallback) | ✅ Covered |
| TC-006 | ActiveStorage attached, write flag enabled | ActiveStorage URL | ✅ Covered |
| TC-007 | No ActiveStorage, write flag enabled | CarrierWave URL (fallback) | ✅ Covered |

#### Presence Check Tests

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-008 | CarrierWave file only | true | ✅ Covered |
| TC-009 | ActiveStorage attachment only | true | ✅ Covered |
| TC-010 | Neither file exists | false | ✅ Covered |
| TC-011 | Both files exist | true | ✅ Covered |

#### Read Scenarios (Feature Tests)

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-012 | Speaker avatar, read disabled | CarrierWave URL served | ✅ Covered |
| TC-013 | Speaker avatar, read enabled | ActiveStorage URL served | ✅ Covered |
| TC-014 | Site logo, no file | Default URL | ✅ Covered |
| TC-015 | News thumbnail, read disabled | CarrierWave URL served | ✅ Covered |
| TC-016 | News thumbnail, read enabled | ActiveStorage URL served | ✅ Covered |
| TC-017 | Sponsor logo, read disabled | CarrierWave URL served | ✅ Covered |
| TC-018 | Sponsor logo, read enabled | ActiveStorage URL served | ✅ Covered |
| TC-019 | Partner logo, read disabled | CarrierWave URL served | ✅ Covered |
| TC-020 | Partner logo, read enabled | ActiveStorage URL served | ✅ Covered |
| TC-021 | Slider image, read disabled | CarrierWave URL served | ✅ Covered |
| TC-022 | Slider image, read enabled | ActiveStorage URL served | ✅ Covered |
| TC-023 | Game thumbnail, read disabled | CarrierWave URL served | ✅ Covered |
| TC-024 | Game thumbnail, read enabled | ActiveStorage URL served | ✅ Covered |

#### Write Scenarios (Feature Tests)

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-025 | Admin uploads Speaker avatar, write enabled | Saved to ActiveStorage | ✅ Covered |
| TC-026 | ActiveStorage file exists, read disabled | ActiveStorage URL served | ✅ Covered |
| TC-027 | CarrierWave file only, write enabled | CarrierWave URL served | ✅ Covered |
| TC-028 | Admin uploads Sponsor logo, write enabled | Saved to ActiveStorage | ✅ Covered |
| TC-029 | Admin uploads News thumbnail, write enabled | Saved to ActiveStorage | ✅ Covered |
| TC-030 | Admin uploads Slider image, write enabled | Saved to ActiveStorage | ✅ Covered |
| TC-031 | Admin uploads Game thumbnail, write enabled | Saved to ActiveStorage | ✅ Covered |
| TC-032 | Admin uploads Site logo, write enabled | Saved to ActiveStorage | ❌ Skipped (public tenant) |

#### Not Covered

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-033 | Image variant generation | Processed variant returned | ❌ Not Covered |
| TC-034 | Migration task verification | Files copied correctly | ❌ Not Covered |
| TC-035 | Filename collision detection | No duplicate attachments | ❌ Not Covered |

### Feature Flags

| Flag | Default | Purpose |
|------|---------|---------|
| `active_storage_read` | **Disabled** | Serve files from ActiveStorage when available |
| `active_storage_write` | **Disabled** | New uploads go to ActiveStorage, forms use `{field}_attachment` |

**Important:** Both flags are disabled by default after setup. This means CarrierWave continues to serve all files until you explicitly enable a flag.

**Flag Behavior:**
- When `active_storage_read` is enabled: Serve from ActiveStorage if attached, else fallback to CarrierWave
- When `active_storage_write` is enabled:
  - Admin forms show `{field}_attachment` file input instead of CarrierWave field
  - Files uploaded via ActiveStorage are also served from ActiveStorage (even if `active_storage_read` is disabled)
  - This ensures you can see what you just uploaded

**Recommended migration order:**
1. Deploy code with flags disabled
2. Run migration tasks to copy existing files
3. Enable `active_storage_read` to serve migrated files from ActiveStorage
4. Enable `active_storage_write` to start accepting new uploads via ActiveStorage

## Migration Playbook

### Phase 1: Deploy Code

Deploy the migration code to production. At this point:
- Feature flags are disabled
- CarrierWave continues to work exactly as before
- No user-facing changes

```bash
# Verify deployment
bin/rails runner "puts 'HasMigratedUpload loaded' if defined?(HasMigratedUpload)"
```

### Phase 2: Setup Feature Flags

```bash
bin/rails active_storage_migration:setup_flags
```

This creates the Flipper feature flags (disabled by default).

### Phase 3: Migrate Files

Run the migration to copy files from CarrierWave to ActiveStorage:

```bash
# Migrate all models
bin/rails active_storage_migration:migrate

# Or migrate one model at a time
bin/rails active_storage_migration:migrate MODEL=Speaker
bin/rails active_storage_migration:migrate MODEL=Site
bin/rails active_storage_migration:migrate MODEL=News
# ... etc
```

The migration:
- **Skips records already migrated** (checks `attachment.attached?` first)
- **Skips records without CarrierWave files** (checks `uploader.url.blank?`)
- Downloads each file from CarrierWave URL
- Attaches it to ActiveStorage
- Logs progress and errors

**Multi-Tenancy Support:** The migration properly handles both Apartment (schema-based) and ActsAsTenant (column-based) multi-tenancy:
- **Tenant-scoped models** (News, Speaker, etc.): Iterates through all tenant schemas
- **Global records** (`site_id = NULL`): Processed in each tenant schema separately
- **Non-tenant models** (Site): Processed in public schema

**Safe to re-run:** You can run the migration multiple times. It will only process records that haven't been migrated yet.

### Phase 4: Verify Migration

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

News#thumbnail: INCOMPLETE
  Total records:      100
  With CarrierWave:   98
  With ActiveStorage: 95
  Missing:            3
```

Re-run migration for incomplete models until all show "OK".

### Phase 5: Enable ActiveStorage Read

Once all files are migrated and verified:

```bash
bin/rails active_storage_migration:enable_read
```

Files will now be served from ActiveStorage. Monitor for:
- 404 errors on image URLs
- Slow response times (variant generation)
- Error logs

### Phase 6: (Optional) Enable ActiveStorage Write

To have new uploads go directly to ActiveStorage:

```bash
bin/rails active_storage_migration:enable_write
```

All admin forms are already configured to conditionally use `{field}_attachment` when this flag is enabled. Model validations use the `{field}_present?` method which accepts uploads from either CarrierWave or ActiveStorage.

### Phase 7: Cleanup (After 1 Year)

After the retention period:

1. Remove CarrierWave uploaders and `mount_uploader` calls
2. Remove gems: `carrierwave`, `fog-aws`, `mini_magick` (keep `aws-sdk-s3`)
3. Remove ImageMagick from Dockerfile (keep only `vips`)
4. Simplify `HasMigratedUpload` to remove fallback logic
5. Delete old CarrierWave files from S3

## Rollback

At any point, rollback by disabling feature flags:

```bash
# Disable ActiveStorage read (fall back to CarrierWave)
bin/rails active_storage_migration:disable_read

# Disable ActiveStorage write
bin/rails active_storage_migration:disable_write
```

CarrierWave files remain intact and will be served immediately.

## Rake Tasks Reference

```bash
# Setup
bin/rails active_storage_migration:setup_flags    # Create feature flags

# Control
bin/rails active_storage_migration:enable_read    # Serve from ActiveStorage
bin/rails active_storage_migration:disable_read   # Serve from CarrierWave
bin/rails active_storage_migration:enable_write   # New uploads to ActiveStorage
bin/rails active_storage_migration:disable_write  # New uploads to CarrierWave

# Status
bin/rails active_storage_migration:status         # Show current flag status

# Migration
bin/rails active_storage_migration:migrate        # Copy all files
bin/rails active_storage_migration:migrate MODEL=Speaker  # Copy specific model
bin/rails active_storage_migration:verify         # Check migration completeness
```
