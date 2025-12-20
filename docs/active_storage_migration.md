# CarrierWave to ActiveStorage Migration

This document describes the migration plan from CarrierWave to ActiveStorage for file uploads.

## Overview

The migration uses a **dual-system approach** that allows both CarrierWave and ActiveStorage to coexist during the transition period. ActiveStorage is used by default for all new uploads, with automatic fallback to CarrierWave for existing files.

### Key Decisions

- **ActiveStorage by default** - New uploads always go to ActiveStorage
- **Automatic fallback** - If no ActiveStorage attachment exists, serve from CarrierWave
- **Optional bulk migration** - Existing files can be copied to ActiveStorage in the background
- **Rails proxy URLs** for serving files (simpler setup)
- **Backward-compatible** `_url` methods with automatic fallback
- **Shared assets** - ActiveStorage uses flat structure without tenant-scoping (simpler than CarrierWave's tenant-specific paths)

### Migration Phases

| Phase | Status | Description |
|-------|--------|-------------|
| 1. Dual-system with feature flags | ✅ Complete | Both systems coexist, flags control behavior |
| 2. Verify fallback works correctly | ✅ Complete | Tested AS → CW fallback logic |
| 3. Remove feature flags | 🔄 Current | Simplify to always-AS with auto-fallback |
| 4. Bulk migrate existing files | ⏳ Pending | Copy CarrierWave files to ActiveStorage |
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
3. The `{field}_url` method uses simple fallback logic:
   - **ActiveStorage attached?** → Return ActiveStorage URL (or variant)
   - **No ActiveStorage attachment?** → Fall back to CarrierWave URL
4. The `{field}_present?` method checks both CarrierWave and ActiveStorage for presence
5. Model validations use `{field}_present?` to accept uploads from either system
6. Admin forms always use `{field}_attachment` (ActiveStorage) for new uploads

### URL Generation Decision Table

| ActiveStorage Attached | Result |
|------------------------|--------|
| Yes | ActiveStorage URL |
| No | CarrierWave URL (fallback) |

**Note:** CarrierWave URL generation delegates directly to the uploader without file existence checks, matching CarrierWave's native `_url` method behavior.

### Feature Flags (To Be Removed)

> **Note:** Feature flags were used during initial development to safely test the dual-system behavior. Now that fallback logic is verified working, feature flags add unnecessary complexity and will be removed.

#### Current State (With Flags)

| Flag | Default | Purpose |
|------|---------|---------|
| `active_storage_read` | Disabled | Serve files from ActiveStorage when available |
| `active_storage_write` | Enabled | New uploads go to ActiveStorage |

**Current behavior with `active_storage_write` enabled:**
```ruby
# HasMigratedUpload#field_url (current implementation)
use_active_storage = attachment.attached? &&
                     (Flipper.enabled?(:active_storage_read) ||
                      Flipper.enabled?(:active_storage_write))
```

#### Target State (Without Flags)

After removing feature flags, the logic simplifies to:

```ruby
# HasMigratedUpload#field_url (target implementation)
if attachment.attached?
  active_storage_url_for(attachment, version, variants)
else
  carrierwave_url_for(field, version)
end
```

**Benefits of removing feature flags:**
- Simpler code - no Flipper dependency for this feature
- Simpler mental model - always AS with CW fallback
- Less configuration to manage
- Predictable behavior without hidden state

#### Migration Tasks for Flag Removal

1. Update `HasMigratedUpload` to remove Flipper checks
2. Remove flag-related rake tasks (`setup_flags`, `enable_*`, `disable_*`)
3. Update admin forms to always use ActiveStorage fields (remove conditional)
4. Update/remove feature tests that depend on flag states
5. Clean up Flipper flags from database

### Test Cases

#### URL Generation Tests

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-001 | ActiveStorage attached | ActiveStorage URL | ⏳ Pending |
| TC-002 | ActiveStorage attached, version requested | ActiveStorage variant URL | ⏳ Pending |
| TC-003 | No ActiveStorage, CarrierWave exists | CarrierWave URL (fallback) | ⏳ Pending |
| TC-004 | No ActiveStorage, CarrierWave version requested | CarrierWave version URL (fallback) | ⏳ Pending |

#### Presence Check Tests

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-005 | CarrierWave file only | true | ⏳ Pending |
| TC-006 | ActiveStorage attachment only | true | ⏳ Pending |
| TC-007 | Neither file exists | false | ⏳ Pending |
| TC-008 | Both files exist | true | ⏳ Pending |

#### Fallback Scenarios (Feature Tests)

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-009 | Speaker with ActiveStorage avatar | ActiveStorage URL served | ⏳ Pending |
| TC-010 | Speaker with only CarrierWave avatar | CarrierWave URL served (fallback) | ⏳ Pending |
| TC-011 | Site logo, no file | Default URL | ⏳ Pending |
| TC-012 | News with ActiveStorage thumbnail | ActiveStorage URL served | ⏳ Pending |
| TC-013 | News with only CarrierWave thumbnail | CarrierWave URL served (fallback) | ⏳ Pending |
| TC-014 | Sponsor with ActiveStorage logo | ActiveStorage URL served | ⏳ Pending |
| TC-015 | Partner with ActiveStorage logo | ActiveStorage URL served | ⏳ Pending |
| TC-016 | Slider with ActiveStorage image | ActiveStorage URL served | ⏳ Pending |
| TC-017 | Game with ActiveStorage thumbnail | ActiveStorage URL served | ⏳ Pending |

#### Admin Upload Scenarios (Feature Tests)

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-018 | Admin uploads Speaker avatar | Saved to ActiveStorage | ⏳ Pending |
| TC-019 | Admin uploads Sponsor logo | Saved to ActiveStorage | ⏳ Pending |
| TC-020 | Admin uploads News thumbnail | Saved to ActiveStorage | ⏳ Pending |
| TC-021 | Admin uploads Slider image | Saved to ActiveStorage | ⏳ Pending |
| TC-022 | Admin uploads Game thumbnail | Saved to ActiveStorage | ⏳ Pending |
| TC-023 | Admin uploads Site logo | Saved to ActiveStorage | ⏳ Pending (public tenant) |

#### Not Covered

| ID | Input | Expected Output | Status |
|----|-------|-----------------|--------|
| TC-024 | Image variant generation | Processed variant returned | ❌ Not Covered |
| TC-025 | Migration task verification | Files copied correctly | ❌ Not Covered |
| TC-026 | Filename collision detection | No duplicate attachments | ❌ Not Covered |

## Migration Playbook

### Phase 1: Deploy Code

Deploy the migration code to production:

```bash
# Verify deployment
bin/rails runner "puts 'HasMigratedUpload loaded' if defined?(HasMigratedUpload)"
```

At this point:
- New uploads automatically go to ActiveStorage
- Existing CarrierWave files continue to work via fallback
- Admin forms use ActiveStorage file inputs
- No configuration required

### Phase 2: Monitor

After deployment, monitor for:
- New uploads working correctly in admin
- Existing images displaying properly (via CarrierWave fallback)
- No 404 errors on image URLs

### Phase 3: (Optional) Bulk Migrate Existing Files

If you want to migrate existing CarrierWave files to ActiveStorage (recommended for consistency and eventual CarrierWave removal):

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

### Phase 4: (Optional) Verify Migration

If you ran bulk migration, verify completeness:

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

### Phase 5: Cleanup (After 1 Year)

After the retention period:

1. Remove CarrierWave uploaders and `mount_uploader` calls
2. Remove gems: `carrierwave`, `fog-aws`, `mini_magick` (keep `aws-sdk-s3`)
3. Remove ImageMagick from Dockerfile (keep only `vips`)
4. Simplify `HasMigratedUpload` to remove fallback logic
5. Delete old CarrierWave files from S3

## Rollback

The dual-system design means CarrierWave files remain intact as fallback.

### Current Rollback (With Feature Flags)

While feature flags exist, rollback is simple:

```bash
# Disable ActiveStorage write (new uploads go to CarrierWave)
bin/rails active_storage_migration:disable_write

# Disable ActiveStorage read (always use CarrierWave)
bin/rails active_storage_migration:disable_read
```

**Note:** Files already uploaded to ActiveStorage will still be served (fallback logic checks AS first when flags are enabled).

### Future Rollback (After Flag Removal)

After feature flags are removed, rollback requires code changes:

1. **New uploads failing?** - Check ActiveStorage configuration and S3 credentials
2. **Existing files not showing?** - Verify CarrierWave URLs are still accessible
3. **Need to revert completely?** - Restore CarrierWave form fields in admin views

The simplified design trades rollback convenience for code simplicity. Since the fallback logic is well-tested, this is an acceptable tradeoff.

## Rake Tasks Reference

### Current Tasks (With Feature Flags)

```bash
# Setup
bin/rails active_storage_migration:setup_flags    # Create feature flags (enables write by default)

# Control
bin/rails active_storage_migration:enable_read    # Serve from ActiveStorage
bin/rails active_storage_migration:disable_read   # Serve from CarrierWave
bin/rails active_storage_migration:enable_write   # New uploads to ActiveStorage
bin/rails active_storage_migration:disable_write  # New uploads to CarrierWave

# Status
bin/rails active_storage_migration:status         # Show current flag status

# Bulk Migration
bin/rails active_storage_migration:migrate                 # Copy all existing files
bin/rails active_storage_migration:migrate MODEL=Speaker   # Copy specific model
bin/rails active_storage_migration:verify                  # Check migration completeness
```

### Future Tasks (After Flag Removal)

```bash
# Bulk Migration (optional)
bin/rails active_storage_migration:migrate                 # Copy all existing files
bin/rails active_storage_migration:migrate MODEL=Speaker   # Copy specific model
bin/rails active_storage_migration:verify                  # Check migration completeness
bin/rails active_storage_migration:status                  # Show migration statistics
```

Tasks to be removed: `setup_flags`, `enable_read`, `disable_read`, `enable_write`, `disable_write`
