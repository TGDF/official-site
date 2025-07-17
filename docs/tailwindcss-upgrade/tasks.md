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

- [ ] 6. Update Build Process and NPM Commands
  - [ ] Test development CSS build with npm run build:css
  - [ ] Test production CSS build with minification
  - [ ] Verify CSS builds complete without errors in Terminal
  - [ ] Ensure build commands work correctly
  - Satisfies user requirements: 6, 10

- [ ] 7. Clean Up Configuration Files
  - [ ] Remove tailwind.config.js after successful migration
  - [ ] Clean up any unused configuration files
  - [ ] Verify CSS builds work without JavaScript configuration
  - Satisfies user requirements: 3

- [ ] 8. Update Documentation
  - [ ] Update development documentation with TailwindCSS 4.0 changes
  - [ ] Document new CSS configuration approach for team
  - [ ] Update CLAUDE.md with new build process information
  - [ ] Document migration steps and configuration changes
  - Satisfies user requirements: 5, 10