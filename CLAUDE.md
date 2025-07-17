# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup and Dependencies
- `./bin/setup` - Complete setup script for development environment
- `yarn install` - Install JavaScript dependencies
- `bundle exec overcommit --install` - Setup git hooks for code quality

### Development Server
- `./bin/dev` - Start all development processes (Rails server, CSS/JS builders)
- Individual processes: `bin/rails server`, `yarn build:css --watch`, `yarn build --watch`

### Testing
- `bundle exec rspec` - Run RSpec test suite
- `bundle exec cucumber` - Run Cucumber feature tests (BDD)
- `bundle exec rspec spec/components/` - Run ViewComponent tests
- `bundle exec rake coverage` - Generate test coverage report

### Code Quality and Linting
- `bundle exec rubocop` - Ruby linting (configured via .overcommit.yml)
- `bundle exec rubocop -A` - Auto-fix correctable Ruby style issues
- `bundle exec brakeman` - Security analysis
- Git hooks automatically run linting on commit/push via overcommit

### Database
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:seed` - Seed database
- Multi-tenant migrations handled via acts_as_tenant (migrating from Apartment gem)

### TailwindCSS 4.0 Configuration
- **CSS Configuration**: `app/assets/stylesheets/theme.css` - CSS-based theme configuration with @theme directive
- **Build Command**: `yarn build:css` or `npm run build:css` - Compile TailwindCSS
- **Watch Mode**: `yarn build:css --watch` - Auto-rebuild CSS on changes
- **Content Detection**: Uses @source directives for Rails views, components, and JavaScript files
- **No Config File**: TailwindCSS 4.0 uses CSS-based configuration, no tailwind.config.js needed

## Architecture Overview

### Multi-Tenant SaaS Platform
This Rails application powers conference/gaming event websites with a sophisticated multi-tenant architecture:

**Tenant System (migrating from Apartment to acts_as_tenant)**:
- Each `Site` model represents a tenant with isolated data
- Tenants switch based on domain/subdomain routing
- Global admin interface at `/admin` for tenant management
- Tenant-specific admin at `/admin` for content management
- **Migration in progress**: Replacing `ros-apartment` gem with `acts_as_tenant` for simpler multi-tenancy

**Core Domain Models**:
- **Event Management**: `Agenda` → `Speaker` → `Room`/`AgendaTime` with multi-language support
- **Gaming Content**: `Game` with STI variants (`IndieSpace::Game`, `NightMarket::Game`)
- **Partnerships**: `Partner`/`PartnerType` and `Sponsor`/`SponsorLevel` hierarchies
- **CMS**: `News`, `Block`, `Slider`, `Plan` for dynamic content

### Technology Stack

**Backend**: Rails 8.0.2 + Ruby 3.3.0 + PostgreSQL
**Frontend**: Turbo + Stimulus + TailwindCSS 4.0 + esbuild
**File Uploads**: CarrierWave + ImageMagick (required dependency)
**Internationalization**: Mobility gem with zh-TW/en locales
**Authentication**: Devise for admin users
**View Layer**: ERB templates + ViewComponent architecture (migrating from Slim)

### Key Architectural Patterns

**Multi-tenancy**: Most models use `acts_as_tenant :site` with global record support
**i18n**: Mobility-powered translations in most content models
**ViewComponents**: Reusable UI components in `app/components/`
**STI Pattern**: Game models use Single Table Inheritance
**Feature Flags**: Flipper integration for admin UI variants

### File Structure

**Components**: `app/components/` - ViewComponent-based UI components
**Admin Interface**: Migrating from Slim templates to ERB with ViewComponent (use `.html+v2.erb` for new templates)
**Multi-language Routes**: Scoped by `/:lang` parameter
**Asset Pipeline**: esbuild + TailwindCSS 4.0 with CSS-based configuration and watch processes

### Development Notes

**Template Migration**: Actively migrating from Slim to ERB with ViewComponent architecture (prefer ERB+ViewComponent for new features)
**Multi-tenancy Migration**: Transitioning from ros-apartment gem to acts_as_tenant for simplified tenant management
**Tenant Context**: Always verify current tenant context when working with data
**Translations**: Use `HasTranslation` concern for i18n-enabled models
**View Components**: Test components in `spec/components/` and preview with Lookbook (dev only)
**Git Workflow**: Overcommit enforces RuboCop standards and runs Brakeman security checks
**Code Style**: Use `bundle exec rubocop -A` to auto-fix style issues before manual corrections

### Admin Interface Implementation

**Admin V2 System**: The admin interface has two variants controlled by feature flags
- V1: Original CoreUI-based interface (`.erb` templates)
- V2: TailwindCSS 4.0-based interface (`.html+v2.erb` templates) following `docs/ADMIN_UI_COMPONENTS.md`

**Font Awesome Integration**: Uses Font Awesome 4.x via CDN (`https://use.fontawesome.com/`)
- Use `fa fa-*` class format (not `fas fa-*`)
- Icon compatibility: Some FA5+ icons need FA4 equivalents (e.g., `fa-tachometer-alt` → `fa-tachometer`)
- Refer to https://fontawesome.com/v4/icons/ for available icons

**Stimulus Controllers**: Interactive components use Stimulus.js
- Register controllers in `app/javascript/admin.js`
- Place controllers in `app/assets/javascripts/controllers/`
- Use semantic naming (e.g., `sidebar_controller.js` for sidebar functionality)

**UI Documentation**: `docs/ADMIN_UI_COMPONENTS.md` serves as the design system
- All V2 admin components must follow documented patterns
- Includes comprehensive examples for sidebar, cards, forms, tables, etc.
- Updated to reflect Font Awesome 4 compatibility

**Accessibility**: Admin interface includes proper ARIA attributes
- Use `aria-expanded` and `aria-controls` for collapsible sections
- Include `role` attributes for semantic structure
- Ensure keyboard navigation support

**Sidebar Implementation**: Both V1 and V2 sidebars support active state detection
- V1: Uses `admin_sidebar_treeview` helper with automatic `c-show` class for expanded parents
- V2: Uses `admin_v2_sidebar_treeview` helper that detects active children and auto-expands
- Active detection: `current_admin_path_under?` method matches current path with menu items
- Parent expansion: Automatically opens parent menu when any child item is active

### Testing Strategy

**RSpec**: Model and feature tests with FactoryBot fixtures
**Cucumber**: BDD acceptance tests for user flows
**ViewComponent**: Dedicated component testing
**Multi-tenant Testing**: acts_as_tenant handles tenant switching in tests (migrated from Apartment gem)