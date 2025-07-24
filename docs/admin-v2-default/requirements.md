# Feature: Admin v2 Default Interface Migration

Background: The admin interface currently supports two variants - v1 (CoreUI-based) and v2 (TailwindCSS-based). Users can switch between variants using URL parameters (?variant=v2) or feature toggles. We want to make v2 the default interface while providing legacy v1 support through feature toggles only.

## 1. Make Admin v2 the Default Interface

As an admin user
I want the TailwindCSS-based admin interface (v2) to be the default experience
So that I benefit from the modern, responsive design without manual configuration

```gherkin
Scenario: Default interface loads v2 without configuration
  Given I am an authenticated admin user
  And no feature flags are configured for my account
  When I access any admin page
  Then I should see the TailwindCSS-based interface (v2)
  And the page should render using default .erb templates
  And the interface should be fully functional

Scenario: New admin users get v2 by default
  Given a new admin user account is created
  When they first log into the admin panel
  Then they should see the v2 interface by default
  And no additional configuration should be required
```

## 2. Implement Legacy v1 Support via Feature Toggle

As a system administrator
I want to provide temporary v1 access for users who need the legacy interface
So that the migration can be gradual and non-disruptive

```gherkin
Scenario: Enable legacy v1 interface via feature toggle
  Given I am a system administrator
  When I enable the "admin_v1_legacy" feature flag for a specific user
  Then that user should see the CoreUI-based interface (v1)
  And the system should render +v1.erb templates when available
  And all legacy functionality should work as before

Scenario: Disable legacy support returns to default
  Given a user has the "admin_v1_legacy" feature flag enabled
  When I disable the feature flag for that user
  Then they should immediately see the v2 interface
  And the transition should be seamless without data loss
```

## 3. Remove URL Parameter Variant Support

As a developer
I want to simplify the variant selection logic by removing URL parameter support
So that the codebase is cleaner and maintenance is reduced

```gherkin
Scenario: URL variant parameter no longer affects interface
  Given I am an admin user with v2 as default
  When I access admin pages with "?variant=v2" parameter
  Then the parameter should be ignored
  And I should see the v2 interface (same as without parameter)

Scenario: Legacy URL parameters don't break the system
  Given existing bookmarks or links contain "?variant=v2"
  When these URLs are accessed
  Then the system should work normally
  And show the appropriate interface based on feature toggle only
  And no errors should occur
```

## 4. Update Template File Structure

As a developer
I want to reorganize template files to reflect the new default hierarchy
So that the codebase structure is clear and maintainable

```gherkin
Scenario: Rename current templates to reflect new structure
  Given the current template structure exists
  When the migration is applied
  Then current .erb templates should become +v1.erb (legacy)
  And current +v2.erb templates should become .erb (default)
  And all template references should be updated accordingly

Scenario: Verify template resolution works correctly
  Given the new template structure is in place
  When a user with v1 legacy flag accesses admin pages
  Then +v1.erb templates should be rendered
  When a user without flags accesses admin pages
  Then default .erb templates should be rendered
  And no template missing errors should occur
```

## 5. Update Controller Logic and Helpers

As a developer
I want to update the variant selection logic in controllers and helpers
So that the new default behavior is properly implemented

```gherkin
Scenario: Controller variant logic uses feature toggle only
  Given the Admin::BaseController variant logic
  When the new logic is implemented
  Then request.variant should be set to :v1 only when admin_v1_legacy flag is enabled
  And no URL parameter checking should occur
  And the default behavior should use standard templates

Scenario: Helper methods work with new template structure
  Given sidebar and page helper methods exist for both versions
  When templates are reorganized
  Then helper method calls should resolve to correct version
  And admin_sidebar_* helpers should work with +v1.erb templates
  And admin_v2_sidebar_* helpers should work with default .erb templates
```

## 6. Update Feature Toggle Management

As a system administrator
I want clear management of the legacy v1 feature toggle
So that I can control user access to the old interface during transition

```gherkin
Scenario: Configure admin_v1_legacy feature flag
  Given the Flipper admin interface
  When I access feature toggle management
  Then I should see an "admin_v1_legacy" feature flag
  And I should be able to enable it for specific users
  And I should see clear description of what this flag controls

Scenario: Batch enable legacy support for user groups
  Given multiple users need legacy interface access
  When I use Flipper's actor group functionality
  Then I should be able to enable admin_v1_legacy for groups
  And the changes should take effect immediately
  And users should see their interface update on next page load
```

## 7. Update Sidebar Toggle Functionality

As an admin user
I want the sidebar toggle switch to work with the new default behavior
So that I can still switch between interfaces when legacy support is available

```gherkin
Scenario: Sidebar toggle switches to legacy when available
  Given I am using the default v2 interface
  And legacy support is available for my account
  When I click the interface toggle in the sidebar
  Then the admin_v1_legacy flag should be enabled for my account
  And I should immediately see the v1 interface
  And the toggle should reflect the current state

Scenario: Toggle is hidden when legacy support is not available
  Given I am using the default v2 interface
  And legacy support is not enabled for my account
  When I view the sidebar
  Then the interface toggle should not be visible
  And no switching option should be available
```

## 8. Ensure Backward Compatibility

As a system administrator
I want to ensure all existing functionality continues to work
So that the migration doesn't disrupt daily operations

```gherkin
Scenario: All admin features work in both interfaces
  Given both v1 and v2 interfaces are available
  When I test all admin functionality in both versions
  Then CRUD operations should work identically
  And form submissions should process correctly
  And navigation should function properly
  And data should be consistent between versions

Scenario: User preferences and data are preserved
  Given users have existing configurations and data
  When the interface changes to v2 default
  Then all user data should remain intact
  And preferences should be maintained where applicable
  And no data migration should be required
```

## 9. Plan Legacy Interface Deprecation

As a product owner
I want a clear timeline for removing legacy v1 support
So that technical debt is managed and users are prepared for changes

```gherkin
Scenario: Define legacy support timeline
  Given v2 is now the default interface
  When planning future development
  Then a clear timeline for v1 deprecation should be established
  And users should be notified of upcoming changes
  And migration deadlines should be communicated

Scenario: Monitor legacy usage to inform deprecation
  Given the admin_v1_legacy feature flag is in use
  When tracking user adoption
  Then usage statistics should be collected
  And low-usage periods should inform safe deprecation timing
  And user feedback should be gathered before removal
```