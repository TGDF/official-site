# ViewComponent 3 to 4 Upgrade Guide

## Overview
This document outlines the migration process from ViewComponent 3.23.2 to 4.0.x for the TGDF official site.

## Breaking Changes in ViewComponent 4.0

### 1. Removed Default Initializer
ViewComponent 4.0 removed the default initializer from `ViewComponent::Base` that previously accepted arguments.

**Impact**: All components calling `super` in their initializers fail with:
```
ArgumentError: wrong number of arguments (given 1, expected 0)
```

**Solution**: Change `super` to `super()` to call the parent initializer without arguments.

### 2. Other Breaking Changes (Not Affecting This Codebase)
- Removed `use_helper(s)` - ✅ Not used
- Removed `render_component` and monkey patches - ✅ Not used
- Removed `preview_source` - ✅ Not used
- Removed `config.view_component.test_controller` - ✅ Not used
- No `require "view_component/engine"` needed - ✅ Already compliant

## Migration Steps

### Step 1: Update Component Initializers
All 22 components need their `super` calls updated to `super()`:

```ruby
# Before (ViewComponent 3)
def initialize(day:, rooms:)
  super  # passes arguments to parent - causes error in v4
  @day = day
  @rooms = rooms
end

# After (ViewComponent 4)
def initialize(day:, rooms:)
  super()  # calls parent without arguments
  @day = day
  @rooms = rooms
end
```

**Files to update:**
- `app/components/agenda_component.rb`
- `app/components/block_component.rb`
- `app/components/breadcrumb_component.rb`
- `app/components/game_component.rb`
- `app/components/heading_component.rb`
- `app/components/language_switch_button_component.rb`
- `app/components/nav_item_component.rb`
- `app/components/navigation_component.rb`
- `app/components/news_list_item_component.rb`
- `app/components/news_side_item_component.rb`
- `app/components/news_thumbnail_component.rb`
- `app/components/partner_group_component.rb`
- `app/components/partner_item_component.rb`
- `app/components/partner_logo_component.rb`
- `app/components/pass_component.rb`
- `app/components/plan_component.rb`
- `app/components/plan_list_component.rb`
- `app/components/proposal_form_component.rb`
- `app/components/slider_component.rb`
- `app/components/slider_item_component.rb`
- `app/components/speaker_list_item_component.rb`
- `app/components/streaming_track_component.rb`

### Step 2: Update Gemfile
```ruby
# Change from:
gem "view_component"

# To:
gem "view_component", "~> 4.0"
```

### Step 3: Update Dependencies
```bash
bundle update view_component
```

### Step 4: Run Tests
```bash
# Run component tests
bundle exec rspec spec/components/

# Run integration tests
bundle exec cucumber

# Check code style
bundle exec rubocop
```

## Automated Migration Script
You can use this command to update all components at once:

```bash
# Find and update all super calls in components
find app/components -name "*.rb" -type f | xargs sed -i '' 's/^[[:space:]]*super$/    super()/'
```

## Verification Checklist
- [ ] All component initializers updated from `super` to `super()`
- [ ] Gemfile updated to ViewComponent 4.0
- [ ] Bundle update successful
- [ ] All component tests passing
- [ ] All cucumber tests passing
- [ ] RuboCop checks passing
- [ ] Application runs without errors

## Rollback Plan
If issues arise after the upgrade:

1. Revert the Gemfile change
2. Revert all component changes (change `super()` back to `super`)
3. Run `bundle install` to restore ViewComponent 3.x
4. Verify tests pass

## Notes
- The `super()` call is still required due to RuboCop's style guide enforcement
- ViewComponent 4.0 requires Rails >= 7.1.0 (we have 8.0.2 ✅)
- ViewComponent 4.0 requires Ruby >= 3.2.0 (we have 3.3.0 ✅)
- Lookbook gem compatibility should be verified after the upgrade

## References
- [ViewComponent 4.0.0 Changelog](https://viewcomponent.org/CHANGELOG.html#400)
- [ViewComponent Migration Guide](https://viewcomponent.org/guide/migration.html)
- [Dependabot PR #1031](https://github.com/TGDF/official-site/pull/1031)