## Implementation Tasks for TailwindCSS 4.0 Upgrade

- [x] 1. Setup Pre-Upgrade Environment Analysis
  - [x] Audit current TailwindCSS usage in codebase
  - [x] Document current CSS file structure and dependencies
  - [x] Create baseline visual tests for critical UI components
  - [x] Verify current build process works correctly
  - Satisfies user requirements: 1, 6, 9

- [x] 2. Update TailwindCSS Package and Dependencies
  - [x] Add tests to verify package installation and version compatibility
  - [x] Update package.json to use TailwindCSS 4.x
  - [x] Upgrade @tailwindcss/typography to compatible version
  - [x] Resolve any dependency conflicts and ensure clean installation
  - Satisfies user requirements: 1, 8

- [x] 3. Migrate CSS Import Syntax
  - [x] Add tests to verify CSS compilation without errors
  - [x] Replace @tailwind directives with @import "tailwindcss" in theme.css
  - [x] Verify all TailwindCSS utilities are available after migration
  - [x] Test CSS build process with new syntax
  - Satisfies user requirements: 2, 6

- [x] 4. Implement CSS-Based Configuration
  - [x] Add tests to verify custom theme variables work correctly
  - [x] Add @source directives for Rails view detection paths
  - [x] Migrate custom colors and typography from tailwind.config.js to @theme CSS
  - [x] Test that all custom design tokens render correctly
  - Satisfies user requirements: 3, 9

- [x] 5. Update Deprecated Utility Classes
  - [x] Add tests to verify visual consistency before and after class updates
  - [x] Run TailwindCSS upgrade tool to identify deprecated utilities
  - [x] Replace bg-opacity-* with bg-{color}/{opacity} syntax
  - [x] Replace text-opacity-* with text-{color}/{opacity} syntax
  - [x] Update shadow-sm to shadow-xs and blur-sm to blur-xs
  - [x] Verify all UI components render identically after changes
  - Satisfies user requirements: 4

- [ ] 6. Validate Frontend Theme Compatibility
  - [ ] Add tests to verify frontend pages render correctly
  - [ ] Test responsive layouts work as expected
  - [ ] Verify all theme-specific components display properly
  - [ ] Test user-facing features maintain visual consistency
  - Satisfies user requirements: 9

- [ ] 7. Validate Admin Panel V1 (CoreUI) Compatibility
  - [ ] Add tests to verify admin V1 interface remains functional
  - [ ] Test that TailwindCSS utilities don't conflict with CoreUI
  - [ ] Verify all admin V1 components render correctly
  - [ ] Test administrative workflows work without style issues
  - Satisfies user requirements: 9

- [ ] 8. Validate Admin Panel V2 (TailwindCSS) Compatibility
  - [ ] Add tests to verify admin V2 components render correctly
  - [ ] Test sidebar, forms, and tables work as designed
  - [ ] Verify all TailwindCSS-based admin components function properly
  - [ ] Test administrative features maintain usability
  - Satisfies user requirements: 9

- [ ] 9. Update Build Process and NPM Commands
  - [ ] Add tests to verify CSS builds complete without errors
  - [ ] Test development CSS build with npm run build:css
  - [ ] Test production CSS build with minification
  - [ ] Verify deployment compatibility and CI/CD integration
  - [ ] Ensure build commands work identically in all environments
  - Satisfies user requirements: 6, 10

- [ ] 10. Verify Browser Compatibility
  - [ ] Add tests to verify minimum browser version requirements
  - [ ] Test application in Safari 16.4+, Chrome 111+, Firefox 128+
  - [ ] Update browser compatibility documentation if needed
  - [ ] Verify all features work in target browsers
  - Satisfies user requirements: 5

- [ ] 11. Fix Test Suite Failures
  - [ ] Add tests to verify RSpec and Cucumber tests pass
  - [ ] Identify and fix style-related RSpec test failures
  - [ ] Update Cucumber test selectors and expectations
  - [ ] Ensure all existing tests pass with new TailwindCSS version
  - Satisfies user requirements: 7

- [ ] 12. Clean Up Configuration Files
  - [ ] Add tests to verify CSS builds work without tailwind.config.js
  - [ ] Remove tailwind.config.js after successful migration
  - [ ] Clean up any unused configuration files
  - [ ] Document new CSS-based configuration approach
  - Satisfies user requirements: 3

- [ ] 13. Final Integration Testing
  - [ ] Add comprehensive end-to-end tests for all user workflows
  - [ ] Test complete application functionality with TailwindCSS 4.0
  - [ ] Verify performance improvements and new features work
  - [ ] Run full test suite and ensure all tests pass
  - Satisfies user requirements: 1, 9

- [ ] 14. Documentation and Deployment
  - [ ] Update development documentation with TailwindCSS 4.0 changes
  - [ ] Document new CSS configuration approach for team
  - [ ] Create deployment checklist for TailwindCSS 4.0
  - [ ] Prepare rollback plan in case of issues
  - Satisfies user requirements: 5, 10