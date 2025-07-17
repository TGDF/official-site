# TailwindCSS 4.0 Upgrade Requirements

## 1. Update TailwindCSS Package and Dependencies

As a developer
I want to upgrade TailwindCSS from 3.x to 4.x
So that the project can benefit from improved performance and new features

```gherkin
Feature: Upgrade TailwindCSS to version 4.0

  Scenario: Successfully update TailwindCSS package
    Given the project is using TailwindCSS version 3.4.17
    When I update the package.json to use TailwindCSS 4.x
    Then the new version should be installed without conflicts
    And all existing styles should continue to work
```

## 2. Migrate CSS Import Syntax

As a developer
I want to update the CSS import syntax to match TailwindCSS 4.0 requirements
So that the styles are properly loaded and compiled

```gherkin
Feature: Update CSS import syntax

  Scenario: Replace @tailwind directives with new import syntax
    Given the theme.css file uses @tailwind directives
    When I replace "@tailwind base/components/utilities" with "@import 'tailwindcss'"
    Then the CSS should compile without errors
    And all TailwindCSS utilities should be available
```

## 3. Migrate Configuration to CSS

As a developer
I want to migrate tailwind.config.js settings to CSS
So that we can leverage TailwindCSS 4.0's CSS-based configuration

```gherkin
Feature: Migrate configuration from JavaScript to CSS

  Scenario: Convert theme extensions to CSS variables
    Given the project has custom colors and typography in tailwind.config.js
    When I migrate these settings to CSS using @theme directive
    Then the tailwind.config.js file can be removed
    And all custom design tokens should work via CSS

  Scenario: Ensure content paths work without config file
    Given the project scans specific paths for Tailwind classes
    When tailwind.config.js is removed
    Then TailwindCSS 4.0 should auto-detect content paths
    And all utility classes should be included in the build
```

## 4. Fix Breaking Changes in Utility Classes

As a developer
I want to update deprecated utility classes
So that the UI renders correctly with TailwindCSS 4.0

```gherkin
Feature: Update deprecated utility classes

  Scenario: Replace deprecated opacity utilities
    Given the codebase uses bg-opacity-* classes
    When I search for all deprecated utilities
    Then I should replace them with new opacity modifier syntax
    And the visual appearance should remain the same

  Scenario: Update renamed shadow utilities
    Given the codebase uses shadow-sm classes
    When I update to TailwindCSS 4.0
    Then I should replace shadow-sm with shadow-xs
    And replace shadow with shadow-sm
    And replace other renamed utilities per upgrade guide
    And verify all shadow effects render correctly
```

## 5. Ensure Browser Compatibility

As a developer
I want to verify browser support requirements
So that the application works in all target browsers

```gherkin
Feature: Verify browser compatibility

  Scenario: Check minimum browser versions
    Given TailwindCSS 4.0 requires Safari 16.4+, Chrome 111+, Firefox 128+
    When I review the project's browser support policy
    Then I should confirm these versions are acceptable
    And update any browser compatibility documentation
```

## 6. Update Build Process

As a developer
I want to ensure the build process works with TailwindCSS 4.0
So that CSS is generated correctly in all environments

```gherkin
Feature: Update build configuration

  Scenario: Verify CSS build command
    Given the project uses "tailwindcss -i ./app/assets/stylesheets/theme.css"
    When I run the build:css script with TailwindCSS 4.0
    Then the CSS should compile without errors
    And the output should include all necessary styles

  Scenario: Test production build
    Given the build uses --minify flag
    When I run the production build
    Then the CSS should be properly minified
    And all styles should work in production
```

## 7. Fix Test Failures

As a developer
I want to resolve any test failures caused by the upgrade
So that the CI/CD pipeline passes successfully

```gherkin
Feature: Resolve test suite failures

  Scenario: Fix RSpec test failures
    Given the RSpec tests fail after TailwindCSS upgrade
    When I identify style-related test failures
    Then I should update test expectations to match new output
    And all RSpec tests should pass

  Scenario: Fix Cucumber test failures
    Given the Cucumber tests fail after upgrade
    When I review feature tests for UI changes
    Then I should update selectors and expectations
    And all Cucumber tests should pass
```

## 8. Update Typography Plugin

As a developer
I want to ensure @tailwindcss/typography works with v4
So that prose styles continue to function correctly

```gherkin
Feature: Verify typography plugin compatibility

  Scenario: Test typography plugin with v4
    Given the project uses @tailwindcss/typography 0.5.16
    When TailwindCSS is upgraded to 4.0
    Then the typography plugin should be compatible
    And custom prose styles should render correctly
```

## 9. Ensure Frontend and Admin Panel Compatibility

As a developer
I want to ensure both frontend and admin interfaces work after upgrade
So that all user-facing and administrative features function correctly

```gherkin
Feature: Verify frontend and admin compatibility

  Scenario: Test frontend theme styles
    Given the frontend uses TailwindCSS for theme styling
    When TailwindCSS is upgraded to 4.0
    Then all frontend pages should render correctly
    And responsive layouts should work as expected

  Scenario: Test admin panel V1 (CoreUI)
    Given the admin V1 uses CoreUI with some Tailwind utilities
    When TailwindCSS is upgraded to 4.0
    Then the admin V1 interface should remain functional
    And no style conflicts should occur with CoreUI

  Scenario: Test admin panel V2 (TailwindCSS)
    Given the admin V2 is built entirely with TailwindCSS
    When TailwindCSS is upgraded to 4.0
    Then all admin V2 components should render correctly
    And the sidebar, forms, and tables should work as designed
```

## 10. Test Build Process with NPM

As a developer
I want to test the CSS build using npm commands
So that the deployment process works identically

```gherkin
Feature: Verify npm build process

  Scenario: Test development CSS build
    Given the project uses npm run build:css for CSS compilation
    When I run the build with TailwindCSS 4.0
    Then the command should execute without errors
    And the output CSS should contain all required styles

  Scenario: Test production CSS build with minification
    Given the build:css script includes --minify flag
    When I run npm run build:css in production mode
    Then the CSS should be properly minified
    And file size should be optimized for production

  Scenario: Verify deployment compatibility
    Given the deployment uses npm for building assets
    When TailwindCSS 4.0 is installed via npm
    Then the same build commands should work in CI/CD
    And no additional configuration should be required
```