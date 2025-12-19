# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup and Dependencies
- `./bin/setup` - Complete setup script for development environment
- `yarn install` - Install JavaScript dependencies
- `bundle exec overcommit --install` - Setup git hooks for code quality
- **Requires**: ImageMagick installed for CarrierWave image processing

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

### Code Quality and Linting
- `bundle exec rubocop` - Ruby linting
- `bundle exec rubocop -A` - Auto-fix correctable Ruby style issues
- `bundle exec brakeman` - Security analysis
- Git hooks automatically run linting on commit/push via overcommit

### Database
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:seed` - Seed database

## Architecture Overview

### Multi-Tenant SaaS Platform
This Rails 8.1.1 application powers conference/gaming event websites (TGDF - Taipei Game Developer Forum) with multi-tenant architecture:

**Tenant System (dual implementation during migration)**:
- **Apartment gem**: PostgreSQL schema-based isolation (original implementation)
- **acts_as_tenant gem**: Column-based isolation (migration target)
- Each `Site` model represents a tenant with isolated data
- Tenants switch based on domain via `Middleware::FullHostElevators`
- Models use `acts_as_tenant :site, optional: true, has_global_records: true`

**Core Domain Models**:
- **Event Management**: `Agenda` → `Speaker` → `Room`/`AgendaTime` with multi-language support
- **Gaming Content**: `Game` with STI variants (`IndieSpace::Game`, `NightMarket::Game`)
- **Partnerships**: `Partner`/`PartnerType` and `Sponsor`/`SponsorLevel` hierarchies
- **CMS**: `News`, `Block`, `Slider`, `Plan` for dynamic content
- **Configuration**: `Site` with `SiteOption` for dynamic settings via `store_attribute`

### Technology Stack

- **Backend**: Rails 8.1.1 + Ruby 3.3.0 + PostgreSQL
- **Frontend**: Turbo + Stimulus + TailwindCSS 4.0 + esbuild
- **File Uploads**: CarrierWave + ImageMagick
- **Internationalization**: Mobility gem with zh-TW/en locales
- **Authentication**: Devise for admin users
- **View Layer**: ERB templates + ViewComponent (migrating from Slim)
- **Functional patterns**: dry-monads, dry-transaction for business logic

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

**Feature Flags**: Flipper for admin UI variants and feature toggles

### Admin Interface

**Dual Admin System** (controlled by Flipper feature flags):
- **V1**: CoreUI-based interface (`.erb` or `.html+v1.slim` templates)
- **V2**: TailwindCSS 4.0-based interface (`.html+v2.erb` templates)

Use `docs/ADMIN_UI_COMPONENTS.md` as the design system for V2 admin components.

**Font Awesome 4.x**: Use `fa fa-*` class format (not `fas fa-*`). Reference https://fontawesome.com/v4/icons/

**Stimulus Controllers**: Register in `app/javascript/admin.js`, place in `app/assets/javascripts/controllers/`

**Sidebar Active State**: `admin_v2_sidebar_treeview` helper auto-expands parent menus when child items are active

### TailwindCSS 4.0

- **Configuration**: `app/assets/stylesheets/theme.css` (CSS-based with `@theme` directive)
- **Build**: `yarn build:css` or watch with `yarn build:css --watch`
- **No tailwind.config.js**: TailwindCSS 4.0 uses CSS-based configuration

### File Structure

- `app/components/` - ViewComponent-based UI components (test in `spec/components/`, preview at `/lookbook` in dev)
- `app/uploaders/` - CarrierWave file upload configurations
- `lib/middleware/full_host_elevators.rb` - Domain-to-tenant routing
- `docs/ADMIN_UI_COMPONENTS.md` - Admin V2 design system

### Development Notes

- **Template preference**: Use ERB + ViewComponent for new features (migrating from Slim)
- **Admin V2 templates**: Use `.html+v2.erb` extension
- **Translations**: Use Mobility for content models, `HasTranslation` concern for language-scoped models
- **Testing multi-tenancy**: `spec/support/apartment.rb` handles tenant switching in tests
- **Code style**: Run `bundle exec rubocop -A` to auto-fix before manual corrections
