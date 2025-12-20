# Dual Upload System (CarrierWave + ActiveStorage)

Technical reference for the dual-system approach during migration.

**Parent document:** [../tenant_consolidation.md](../tenant_consolidation.md)

## Overview

During the migration period, both CarrierWave and ActiveStorage coexist. The system uses **schema-based routing** to determine which storage backend to use.

## Key Components

### HasMigratedUpload Concern

**File:** `app/models/concerns/has_migrated_upload.rb`

Provides dual-system support for models with uploads:

```ruby
class Slider < ApplicationRecord
  include HasMigratedUpload

  mount_uploader :image, SliderUploader           # CarrierWave
  has_migrated_upload :image, variants: ImageVariants::SLIDER  # ActiveStorage
end
```

This creates:
- `image` - CarrierWave uploader
- `image_attachment` - ActiveStorage attachment
- `image_url(version)` - Smart URL method with fallback
- `image_present?` - Checks both systems

### URL Generation Logic

```ruby
def image_url(version = nil)
  # Models in tenant schema always use CarrierWave
  return carrierwave_url_for(:image, version) if model_in_tenant_schema?

  # Models in public schema use ActiveStorage with fallback
  if image_attachment.attached?
    active_storage_url_for(image_attachment, version, variants)
  else
    carrierwave_url_for(:image, version)
  end
end
```

### Decision Table

| Model Schema | ActiveStorage Attached | Result |
|--------------|------------------------|--------|
| Tenant schema (Apartment) | Any | CarrierWave URL |
| Public schema | Yes | ActiveStorage URL |
| Public schema | No | CarrierWave URL (fallback) |

## S3 Path Structure

### CarrierWave (tenant-scoped)

```
uploads/{tenant_name}/{model_class}/{field}/{id}/{filename}
uploads/{tenant_name}/{model_class}/{field}/{id}/{version}_{filename}
```

### ActiveStorage (flat)

```
{random_key}/{filename}
```

ActiveStorage uses a single flat namespace because:
- Files are referenced by `ActiveStorage::Blob` records
- Tenant isolation is maintained at the application level
- No need for tenant-scoping in the storage path

## Image Variants

**File:** `app/models/concerns/image_variants.rb`

Defines variant configurations matching CarrierWave versions:

```ruby
module ImageVariants
  SLIDER = {
    large: { resize_to_fill: [1920, 850] },
    thumb: { resize_to_fill: [384, 170] }
  }.freeze
end
```

## Admin Form Helper

**File:** `app/helpers/admin/upload_helper.rb`

```ruby
def upload_field_for(model, field)
  if model_ready_for_active_storage?(model)
    :"#{field}_attachment"  # ActiveStorage
  else
    field                   # CarrierWave
  end
end
```

## Infrastructure Requirements

### Image Processing

| Library | Used By | Package (Alpine) |
|---------|---------|------------------|
| ImageMagick | CarrierWave (MiniMagick) | `imagemagick` |
| libvips | ActiveStorage (ruby-vips) | `vips` |

**Dockerfile during migration:**
```dockerfile
RUN apk add --no-cache ... imagemagick imagemagick-jpeg ... vips
```

**Dockerfile after migration:**
```dockerfile
RUN apk add --no-cache ... vips
```

### Why vips?

- 4-8x faster for common operations
- Uses less memory (streaming vs loading entire image)
- Better quality for resizing operations
- Native Rails 7+ default

## Apartment Configuration

ActiveStorage tables are excluded from tenant schemas:

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

## Future Cleanup

After all models are consolidated to public schema:

1. Remove `model_in_tenant_schema?` checks
2. Remove `upload_field_for` helper (always use `{field}_attachment`)
3. Remove CarrierWave fallback logic
4. Remove CarrierWave uploaders and gems
5. Remove ImageMagick from Dockerfile
