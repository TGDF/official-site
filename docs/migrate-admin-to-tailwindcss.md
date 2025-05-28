<!-- docs/migrate-admin-to-tailwindcss.md -->
# Migrate Admin Panel to TailwindCSS

This document outlines the steps to migrate the Rails admin panel from CoreUI to a TailwindCSS-based implementation, using Rails’ `request.variant` feature and the `+v2` view naming convention. The goal is to scaffold a parallel set of views and layouts that load only when `?variant=v2` is present, leaving the existing CoreUI version untouched.

## Goals
- Introduce a `v2` variant toggle for admin views.
- Create a TailwindCSS-based layout (`admin.html+v2.erb`).
- Scaffold new TailwindCSS views alongside existing CoreUI views using `index.html+v2.erb` (and other `+v2` suffixes).
- Ensure zero disruption to the current admin UI unless explicitly opting into `variant=v2`.

## Prerequisites
- Rails application with an existing CoreUI-based admin panel.
- TailwindCSS already integrated and compiled (no setup needed in this stage).

## Workflow

This project follows trunk-based development:
- All changes land on `main` (trunk) behind the `variant=v2` toggle.
- If using branches for pull requests, keep them short-lived (merge within a day) and merge promptly.
- Ensure each commit is safe for release (feature off by default).

## Steps

### 1. Enable `v2` Variant Toggle
1. In `Admin::BaseController` (or your `ApplicationController`), add a `before_action` to detect the toggle:
   ```ruby
   before_action do
     request.variant = :v2 if params[:variant] == 'v2'
   end
   ```
2. Confirm that without `?variant=v2`, the admin controllers continue rendering existing CoreUI views.

### 2. Create a TailwindCSS Layout
1. Copy your existing layout:
   ```
   cp app/views/layouts/admin.html.erb \
      app/views/layouts/admin.html+v2.erb
   ```
2. In `admin.html+v2.erb`, replace CoreUI stylesheet and script tags with your compiled TailwindCSS include (e.g., `<%= stylesheet_pack_tag 'tailwind' %>`).

### 3. Scaffold `+v2` Views
For each admin view under `app/views/admin/...`:
1. Copy the existing view:
   ```
   cp app/views/admin/<resource>/action.html.erb \
      app/views/admin/<resource>/action.html+v2.erb
   ```
2. In each new `+v2` file, strip out CoreUI markup and begin building the page markup with Tailwind utility classes.

### 4. Create Shared `+v2` Partials
1. Identify shared partials (e.g., sidebar, header, footer).
2. Copy them with a `+v2` suffix:
   ```
   cp app/views/admin/shared/_sidebar.html.erb \
      app/views/admin/shared/_sidebar.html+v2.erb
   ```
3. In `admin.html+v2.erb`, render these partials normally; Rails will resolve the `+v2` variant automatically.

### 5. Smoke Test
1. Visit `/admin/dashboard` → confirms the original CoreUI UI.
2. Visit `/admin/dashboard?variant=v2` → loads `dashboard/index.html+v2.erb` within `admin.html+v2.erb`, verifying Tailwind assets and layout.

### 6. Iterate Page-by-Page
For each admin section (e.g., Users, Reports, Settings):
- Copy its view to `+v2` as above.
- Convert markup to use Tailwind utility classes and your design system.
- Test rendering under `?variant=v2`.

## Deliverables
- Changes committed to `main` (trunk) behind the `variant=v2` toggle. If branches are used for PRs, keep them short-lived and merge promptly.
- `app/views/layouts/admin.html+v2.erb` loading TailwindCSS.
- A set of scaffolded `+v2` view files (dashboard, shared partials, etc.).
- No changes to CoreUI views or layouts unless explicitly requested via `variant=v2`.

After completing these steps and verifying the Tailwind-styled admin pages under the `v2` variant, you can remove CoreUI assets, layouts, and views.