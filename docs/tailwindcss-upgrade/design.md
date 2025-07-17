# TailwindCSS 4.0 Upgrade System Design Document

## Feature Overview
Upgrade the TGDF official site from TailwindCSS 3.x to 4.0, migrating from JavaScript configuration to CSS-based configuration while ensuring all Rails views are properly detected.

## Architecture Planning

### Key Changes
- Remove `tailwind.config.js` and migrate to CSS-based configuration
- Use `@import` and `@theme` directives in CSS files
- Add `@source` directives to ensure Rails view detection
- Update deprecated utility classes

## CSS Migration

### Theme Configuration
```css
/* app/assets/stylesheets/theme.css */
@import "tailwindcss";

/* Explicit content source configuration for Rails views */
@source "../app/views/**/*.erb";
@source "../app/components/**/*.{erb,rb}";
@source "../app/helpers/**/*.rb";
@source "../app/javascript/**/*.js";

@theme {
  /* Custom color palette matching current design system */
  --color-primary: #4f46e5;           /* indigo-600 */
  --color-primary-foreground: #fff;
  --color-secondary: #4b5563;         /* gray-600 */
  --color-secondary-foreground: #fff;
  --color-destructive: #dc2626;       /* red-600 */
  --color-muted: #f3f4f6;            /* gray-100 */
  --color-accent: #db2777;           /* pink-600 */

  /* Typography configuration */
  --font-family-sans: 'Noto Sans TC', system-ui, sans-serif;

  /* Custom prose styles for content */
  --prose-body-light: #e5e7eb;       /* gray-200 */
  --prose-headings-light: #f3f4f6;   /* gray-100 */
}
```

### Utility Class Migration

Key deprecated utilities to update:
- `bg-opacity-*` → `bg-{color}/{opacity}` (removed, use opacity modifiers)
- `text-opacity-*` → `text-{color}/{opacity}` (removed, use opacity modifiers)
- `border-opacity-*` → `border-{color}/{opacity}` (removed, use opacity modifiers)
- `ring-opacity-*` → `ring-{color}/{opacity}` (removed, use opacity modifiers)
- `placeholder-opacity-*` → `placeholder-{color}/{opacity}` (removed, use opacity modifiers)
- `shadow-sm` → `shadow-xs`
- `shadow` → `shadow-sm`
- `drop-shadow-sm` → `drop-shadow-xs`
- `drop-shadow` → `drop-shadow-sm`
- `blur-sm` → `blur-xs`
- `blur` → `blur-sm`
- `backdrop-blur-sm` → `backdrop-blur-xs`
- `backdrop-blur` → `backdrop-blur-sm`
- `rounded-sm` → `rounded-xs`
- `rounded` → `rounded-sm`
- `flex-shrink-*` → `shrink-*`
- `flex-grow-*` → `grow-*`
- `overflow-ellipsis` → `text-ellipsis`
- `decoration-slice` → `box-decoration-slice`
- `decoration-clone` → `box-decoration-clone`

## Implementation Steps

1. **Update Dependencies**
   - Upgrade `tailwindcss` to `^4.0.0`
   - Upgrade `@tailwindcss/typography` to compatible version

2. **Migrate CSS Configuration**
   - Replace `@tailwind` directives with `@import "tailwindcss"`
   - Add `@source` directives for Rails paths
   - Convert `tailwind.config.js` to `@theme` CSS

3. **Update Utility Classes**
   - Run TailwindCSS upgrade tool: `npx @tailwindcss/upgrade`
   - Manually review and update remaining deprecated utilities
   - Test all views for visual consistency

4. **Validation**
   - Verify all Rails views are styled correctly
   - Test both frontend and admin V2 interfaces
   - Ensure CSS builds include all necessary utilities
   - Remove `tailwind.config.js` after successful validation