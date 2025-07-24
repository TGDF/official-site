# Admin V2 Default Interface Migration Tasks

- [x] 1. Create and execute batch template migration with verification
  - Create lib/tasks/admin_migration.rake task
  - Rename current .erb templates to +v1.erb (legacy)
  - Rename current +v2.erb templates to .erb (default)
  - Handle .slim to +v1.erb conversion for sidebar components
  - Verify all admin pages still render correctly after migration
  - _Requirements: R4

- [x] 2. Update controller logic with inverted variant behavior and ensure tests pass
  - Change Admin::BaseController from admin_v2_enabled? to admin_v1_legacy_enabled?
  - Update variant logic: request.variant = :v1 if admin_v1_legacy_enabled?
  - Remove URL parameter variant support
  - Update all controller and integration tests to work with new behavior
  - Ensure all tests pass before completing task
  - _Requirements: R1, R3, R5

- [x] 3. Implement admin_v1_legacy backward compatibility with full testing
  - Setup admin_v1_legacy feature flag in Flipper
  - Update FeatureTogglesController to use new flag
  - Update sidebar toggle logic
  - Test that legacy interface access works correctly
  - Verify toggle switching works in both directions
  - _Requirements: R2, R6, R8