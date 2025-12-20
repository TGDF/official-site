# Slider Migration

Migrate the `Slider` model from Apartment tenant schemas to public schema with `acts_as_tenant`.

**Parent document:** [../tenant_consolidation.md](../tenant_consolidation.md)

## Model Overview

| Property | Value |
|----------|-------|
| Model | `Slider` |
| Complexity | Easy (Order #1) |
| Associations | None |
| Upload field | `image` |
| Variants | `large` (1920x850), `thumb` (384x170) |

### Current Schema

```ruby
# app/models/slider.rb
class Slider < ApplicationRecord
  include HasTranslation
  include HasMigratedUpload

  acts_as_tenant :site, optional: true, has_global_records: true
  mount_uploader :image, SliderUploader
  has_migrated_upload :image, variants: ImageVariants::SLIDER

  enum :language, { 'zh-TW': 0, en: 1 }
  enum :page, { home: 0, indie_spaces: 1, night_market: 2 }

  validates :language, presence: true
  validate { errors.add(:image, :blank) unless image_present? }
end
```

### CarrierWave Path

```
uploads/{tenant_name}/slider/image/{id}/{filename}
uploads/{tenant_name}/slider/image/{id}/large_{filename}
uploads/{tenant_name}/slider/image/{id}/thumb_{filename}
```

## Pre-Migration Checklist

- [ ] `site_id` column exists in `sliders` table
- [ ] `acts_as_tenant :site` configured in model
- [ ] `has_migrated_upload :image` configured in model
- [ ] RDS snapshot created

## Migration Steps

### 1. Create RDS Snapshot

```bash
aws rds create-db-snapshot \
  --db-instance-identifier <your-rds-instance> \
  --db-snapshot-identifier slider-migration-$(date +%Y%m%d)

# Wait for snapshot to be available
aws rds wait db-snapshot-available \
  --db-snapshot-identifier slider-migration-*
```

### 2. Run Consolidation

```bash
# Dry run (if supported)
bin/rails tenant_consolidation:consolidate MODEL=Slider DRY_RUN=true

# Execute
bin/rails tenant_consolidation:consolidate MODEL=Slider
```

### 3. Verify Migration

```bash
bin/rails tenant_consolidation:verify MODEL=Slider
```

Expected output:
```
Slider Migration Verification
============================================================
Total tenant records:    X
Migrated to public:      X
With ActiveStorage:      X
Status: OK
```

### 4. Update Configuration

After verification, add `Slider` to `Apartment.excluded_models`:

```ruby
# config/initializers/apartment.rb
config.excluded_models = %w[
  Site
  AdminUser
  MenuItem
  ActiveStorage::Blob
  ActiveStorage::Attachment
  ActiveStorage::VariantRecord
  Slider  # Add this line
]
```

### 5. Deploy and Verify

1. Deploy configuration change
2. Verify admin forms use `image_attachment` field
3. Verify `slider.image_url` returns ActiveStorage URLs
4. Verify `slider.image_url(:large)` returns variant URLs

## Post-Migration Checklist

- [ ] All sliders in public schema with correct `site_id`
- [ ] `slider.image_url` returns working URLs
- [ ] `slider.image_url(:large)` returns variant URLs
- [ ] Admin forms work with `image_attachment` field
- [ ] No cross-tenant data leakage
- [ ] Configuration deployed with Slider in `excluded_models`

## Rollback

### Level 1: Before Configuration Update

```bash
bin/rails tenant_consolidation:rollback MODEL=Slider
```

This removes consolidated records from public schema. Tenant data remains intact.

### Level 2: After Configuration Update

1. Remove `Slider` from `excluded_models` in `apartment.rb`
2. Deploy configuration change
3. Run rollback task

### Level 3: Emergency (Database Restore)

```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier <new-instance-name> \
  --db-snapshot-identifier slider-migration-*
```

## Notes

- **Validation bypass:** Migration uses `save!(validate: false)` because image validation requires attached file
- **ID remapping:** Original tenant IDs are not preserved; new IDs are generated in public schema
- **Asset download:** Files are downloaded from CarrierWave URLs and re-uploaded to ActiveStorage
