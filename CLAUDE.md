# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup and Dependencies
- `./bin/setup` - Complete setup script for development environment
- `yarn install` - Install JavaScript dependencies
- `bundle exec overcommit --install` - Setup git hooks for code quality
- **Requires**: ImageMagick (CarrierWave) and libvips (ActiveStorage) for image processing

### Development Server
- `./bin/dev` - Start all development processes (Rails server, CSS/JS builders)
- Individual processes: `bin/rails server`, `yarn build:css --watch`, `yarn build --watch`

### Testing
- `bundle exec rspec` - Run full RSpec test suite
- `bundle exec rspec spec/path/to/file_spec.rb` - Run single spec file
- `bundle exec rspec spec/path/to/file_spec.rb:42` - Run specific test at line 42
- `bundle exec cucumber` - Run Cucumber feature tests (BDD)
- `bundle exec rspec spec/components/` - Run ViewComponent tests
- `bundle exec rake coverage` - Generate test coverage report

### Code Quality
- `bundle exec rubocop -A` - Auto-fix Ruby style issues (run this first)
- `bundle exec rubocop` - Check Ruby style without fixing
- `bundle exec brakeman` - Security analysis
- Git hooks run linting on commit/push via overcommit

### Database
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:seed` - Seed database

### Tenant Consolidation (Migration in Progress)
```bash
bin/rails tenant_consolidation:status                          # Check migration status
bin/rails "tenant_consolidation:consolidate[slider]"           # Migrate group to public schema
bin/rails "tenant_consolidation:consolidate[slider,true]"      # Dry run
bin/rails "tenant_consolidation:verify[slider]"                # Verify migration
```
See `docs/tenant_consolidation.md` for full migration guide.

## Architecture Overview

### Multi-Tenant SaaS Platform
Rails 8.1.1 application for conference/gaming event websites (TGDF - Taipei Game Developer Forum).

**Tenant System (dual implementation during migration)**:
- **Apartment gem**: PostgreSQL schema-based isolation (being migrated away)
- **acts_as_tenant gem**: Column-based isolation (migration target)
- Each `Site` model represents a tenant with isolated data
- Tenants switch based on domain via `Middleware::FullHostElevators`
- Models use `acts_as_tenant :site, optional: true`

**File Uploads (dual system during migration)**:
- **CarrierWave**: Original system for tenant-schema models
- **ActiveStorage**: Target system for public-schema models
- `HasMigratedUpload` concern handles URL routing based on model schema location
- See `docs/tenant/dual_system.md` for implementation details

**Core Domain Models**:
- **Event Management**: `Agenda` → `Speaker` → `Room`/`AgendaTime` with multi-language support
- **Gaming Content**: `Game` with STI variants (`IndieSpace::Game`, `NightMarket::Game`)
- **Partnerships**: `Partner`/`PartnerType` and `Sponsor`/`SponsorLevel` hierarchies
- **CMS**: `News`, `Block`, `Slider`, `Plan` for dynamic content
- **Configuration**: `Site` with `SiteOption` for dynamic settings via `store_attribute`

### Technology Stack

- **Backend**: Rails 8.1.1 + Ruby 3.3.0 + PostgreSQL
- **Frontend**: Turbo + Stimulus + TailwindCSS 4.0 + esbuild
- **File Uploads**: CarrierWave (legacy) + ActiveStorage (target)
- **Internationalization**: Mobility gem with zh-TW/en locales
- **Authentication**: Devise for admin users
- **View Layer**: ERB templates + ViewComponent
- **Functional patterns**: dry-monads, dry-transaction for business logic
- **Feature Flags**: Flipper for feature toggles

### Key Patterns

**Multi-tenancy**: Models use `acts_as_tenant :site` - always verify tenant context when working with data

**i18n with Mobility**:
```ruby
class News < ApplicationRecord
  translates :title, :content  # Creates translation records per locale
end
```

**HasTranslation concern**: For models with language enum instead of Mobility:
```ruby
class Block < ApplicationRecord
  include HasTranslation
  enum :language, { 'zh-TW': "zh-TW", en: "en" }
end
```

**STI Pattern**: Game models use Single Table Inheritance (`IndieSpace::Game`, `NightMarket::Game`)

### Admin Interface

Uses TailwindCSS 4.0 with ERB templates. See `docs/ADMIN_UI_COMPONENTS.md` for design system.

**Font Awesome 4.x**: Use `fa fa-*` class format (not `fas fa-*`). Reference https://fontawesome.com/v4/icons/

**Stimulus Controllers**: Register in `app/javascript/admin.js`, place in `app/assets/javascripts/controllers/`

**Sidebar Active State**: `admin_v2_sidebar_treeview` helper auto-expands parent menus when child items are active

### TailwindCSS 4.0

- **Configuration**: `app/assets/stylesheets/theme.css` (CSS-based with `@theme` directive)
- **Build**: `yarn build:css` or watch with `yarn build:css --watch`
- **No tailwind.config.js**: TailwindCSS 4.0 uses CSS-based configuration

### Key Files

- `app/components/` - ViewComponent-based UI components (test in `spec/components/`, preview at `/lookbook` in dev)
- `app/uploaders/` - CarrierWave file upload configurations (legacy)
- `app/models/concerns/has_migrated_upload.rb` - Dual storage system routing
- `lib/middleware/full_host_elevators.rb` - Domain-to-tenant routing
- `docs/ADMIN_UI_COMPONENTS.md` - Admin design system
- `docs/tenant_consolidation.md` - Tenant migration guide

### Development Notes

- **Template preference**: Use ERB + ViewComponent for new features
- **Translations**: Use Mobility for content models, `HasTranslation` concern for language-scoped models
- **Testing multi-tenancy**: `spec/support/apartment.rb` handles tenant switching in tests (creates 'main' tenant)
- **Code style**: Run `bundle exec rubocop -A` to auto-fix before manual corrections
