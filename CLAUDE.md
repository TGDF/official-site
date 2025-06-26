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
- `bundle exec brakeman` - Security analysis
- Git hooks automatically run linting on commit/push via overcommit

### Database
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:seed` - Seed database
- Multi-tenant migrations handled via acts_as_tenant (migrating from Apartment gem)

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
**Frontend**: Turbo + Stimulus + TailwindCSS + esbuild
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
**Asset Pipeline**: esbuild + TailwindCSS with watch processes

### Development Notes

**Template Migration**: Actively migrating from Slim to ERB with ViewComponent architecture (prefer ERB+ViewComponent for new features)
**Multi-tenancy Migration**: Transitioning from ros-apartment gem to acts_as_tenant for simplified tenant management
**Tenant Context**: Always verify current tenant context when working with data
**Translations**: Use `HasTranslation` concern for i18n-enabled models
**View Components**: Test components in `spec/components/` and preview with Lookbook (dev only)
**Git Workflow**: Overcommit enforces RuboCop standards and runs Brakeman security checks

### Testing Strategy

**RSpec**: Model and feature tests with FactoryBot fixtures
**Cucumber**: BDD acceptance tests for user flows
**ViewComponent**: Dedicated component testing
**Multi-tenant Testing**: acts_as_tenant handles tenant switching in tests (migrated from Apartment gem)