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

## Troubleshooting

### "Nil location provided" Error

If you see `ArgumentError: Nil location provided. Can't build URI.` in views, it means:
- A `_url` method returned something `image_tag` can't handle
- Check if the uploader has a `default_url` method
- Verify the `HasMigratedUpload` concern is correctly falling back

### Missing Variants

ActiveStorage generates variants on-demand. First request for a variant may be slow.

To pre-generate variants:
```ruby
News.find_each do |news|
  next unless news.thumbnail_attachment.attached?
  ImageVariants::NEWS_THUMBNAIL.each do |name, options|
    news.thumbnail_attachment.variant(options).processed
  end
end
```

### N+1 Queries

When loading multiple records with attachments, use eager loading to prevent N+1 queries.

**Attachment Naming Pattern:**
`has_migrated_upload :field` creates `has_one_attached :{field}_attachment`

| Model | Field | Eager Loading Scope |
|-------|-------|---------------------|
| News | thumbnail | `with_attached_thumbnail_attachment` |
| Speaker | avatar | `with_attached_avatar_attachment` |
| Partner | logo | `with_attached_logo_attachment` |
| Sponsor | logo | `with_attached_logo_attachment` |
| Slider | image | `with_attached_image_attachment` |
| Game | thumbnail | `with_attached_thumbnail_attachment` |
| Site | logo, figure | `with_attached_logo_attachment`, `with_attached_figure_attachment` |
| Attachment | file | N/A (uses permalinks in content) |

**Note:** `Attachment` files are embedded as permalinks in content and not rendered directly, so eager loading is not needed.

**Controllers with eager loading applied:**

| Controller | Action | Models |
|------------|--------|--------|
| `PagesController` | index | News, Slider, Partner, Sponsor |
| `NewsController` | index, show | News |
| `SpeakersController` | index | Speaker |
| `SponsorsController` | index | Sponsor, Partner (nested) |
| `IndieSpacesController` | index | Slider, Game |
| `NightMarketController` | index | Slider, Game |
| `Admin::SlidersController` | index | Slider |

**Basic usage:**
```ruby
# Before
Speaker.all

# After
Speaker.with_attached_avatar_attachment
```

**Chaining with scopes:**
```ruby
# Before
News.published.latest.limit(10)

# After
News.published.latest.with_attached_thumbnail_attachment.limit(10)
```

**Nested eager loading (for associations):**
```ruby
# Before
SponsorLevel.includes(:sponsors)

# After - include attachment through nested hash
SponsorLevel.includes(sponsors: { logo_attachment_attachment: :blob })
```

**Note:** The nested include uses `{attachment}_attachment` (double suffix) because ActiveStorage creates an association named `{name}_attachment` for `has_one_attached :name`.

### Feature Flag Not Found

If you see `Could not find feature "active_storage_read"`, run:
```bash
bin/rails active_storage_migration:setup_flags
```

### Vips Library Not Found

If you see `LoadError: Could not open library 'vips.so.42'` or `Skipping image analysis because the ruby-vips isn't installed`:

1. **Verify libvips is installed** in your Docker image or server:
   ```bash
   # Alpine Linux
   apk add vips

   # Debian/Ubuntu
   apt-get install libvips42

   # macOS
   brew install vips
   ```

2. **Rebuild and redeploy** the Docker image after adding vips.

3. **Temporary workaround** (not recommended for production):
   ```ruby
   # config/initializers/active_storage.rb
   Rails.application.config.active_storage.variant_processor = :mini_magick
   ```

This error occurs because ActiveStorage uses vips by default for image variant processing, but the library isn't installed on the server.
