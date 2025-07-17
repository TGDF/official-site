# Admin UI Components

## Page Header

### Appearance Description
The page header serves as the primary title area, featuring a clear and bold heading with supporting subtitle text below. It uses text-gray-900 color for the title and text-gray-600 for supplementary text. The spacing below the title (mb-6) ensures clear separation from content sections.

### Example Code

```html
<div class="mb-6">
  <h1 class="text-xl font-semibold text-gray-900 mb-2">Settings</h1>
  <p class="text-gray-600 text-sm">
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Turpis morbi pulvinar venenatis non.
  </p>
</div>
```

### Usage Guidance
Use for main page titles in the Admin Panel. Maintain consistent margin below (mb-6) to separate from subsequent cards or tabs. Titles should use text-xl font size and semibold weight for clarity. Descriptive text should use text-sm size for better readability.

---

## Card

### Appearance Description

Cards are containers with white background, medium border radius, subtle shadow and an optional border to visually separate content blocks.

### Example Code

```html
<div class="bg-white border border-gray-200 rounded-md shadow-xs">
  <div class="p-6">
    <div class="mb-6">
      <h3 class="text-base font-medium text-gray-900 mb-2">Personal Information</h3>
      <p class="text-gray-600 text-sm">Update your personal details and contact information</p>
    </div>
    <!-- Card content -->
  </div>
</div>
```

### Usage Guidance

Use cards to group related UI sections such as form areas or payment info. Consistent padding (p-6) is recommended inside cards to create breathing room. Cards can contain headers, content sections, and footers. Card headers within the content should use text-base font-medium for titles and text-sm for descriptions.

---

## Card Content

### Appearance Description

The card content is the main content area inside a Card with spacing that ensures readability and neat layout.

### Example Code

```html
<div class="p-6">
  <div class="flex items-center justify-between mb-4">
    <div>
      <h3 class="text-base font-medium text-gray-900">
        Subscription Plan: <span class="text-blue-600">Standard</span>
      </h3>
      <p class="text-gray-600 text-sm">Monthly Plan</p>
    </div>
    <button class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium">Cancel Subscription</button>
  </div>

  <div class="flex items-center justify-between py-4 border-t border-gray-200">
    <div>
      <p class="text-gray-900 text-sm">
        Your next payment is <span class="font-semibold">$59.00 USD</span>, to be charged on
        <span class="font-semibold">April 08, 2022</span>
      </p>
    </div>
    <div>
      <p class="text-gray-600 text-sm">Your payment will be automatically renewed each month</p>
    </div>
  </div>
</div>
```

### Usage Guidance

Use consistent padding (p-6) and add vertical spacing between child content elements with margin-bottom (mb-4) for clear separation. Use border-t for separating sections within the card content. Text should use text-sm size for better readability.

---

## Sidebar Container

### Appearance Description

The main sidebar container provides a fixed-width navigation panel with white background, right border, and flexbox layout. It includes header, scrollable navigation, and footer sections.

### Example Code

```html
<div class="w-64 min-w-64 bg-white border-r border-gray-200 flex flex-col shrink-0">
  <!-- Sidebar Header -->
  <div class="px-4 py-3 border-b border-gray-200 h-16 flex items-center">
    <div class="flex items-center gap-2">
      <div class="w-7 h-7 bg-blue-600 rounded-full flex items-center justify-center">
        <div class="w-3.5 h-3.5 bg-white rounded-full"></div>
      </div>
      <span class="text-lg font-semibold text-gray-900">Brand Name</span>
    </div>
  </div>

  <!-- Sidebar Body -->
  <div class="flex-1 overflow-hidden flex flex-col min-h-0">
    <!-- Content goes here -->
  </div>
</div>
```

### Usage Guidance

Use fixed width (w-64) with min-width for consistent layout. The shrink-0 prevents sidebar from shrinking. Use flex-col for vertical stacking and flex-1 for expandable content area. Include overflow-hidden on scrollable sections.

---

## Sidebar Header

### Appearance Description

Sidebar header contains the branding or setup action. It uses prominent blue-600 color for buttons and a clean white background with border-r border-gray-200.

### Example Code

```html
<div class="px-4 py-3 border-b border-gray-200 h-16 flex items-center">
  <div class="flex items-center gap-2">
    <div class="w-7 h-7 bg-blue-600 rounded-full flex items-center justify-center">
      <div class="w-3.5 h-3.5 bg-white rounded-full"></div>
    </div>
    <span class="text-lg font-semibold text-gray-900">Brand Name</span>
  </div>
</div>

<div class="px-3 py-3">
  <button class="w-full bg-blue-600 hover:bg-blue-700 text-white text-sm h-9 px-4 rounded-md flex items-center justify-center">
    <i class="fa fa-plus w-4 h-4 mr-2"></i>
    Connect New Account
  </button>
</div>
```

### Usage Guidance

Use sidebar header for main sidebar actions or branding. Ensure button has sufficient hit area and stands out with strong background color. The logo should be simple and recognizable. Use h-16 for consistent header height.

---

## Sidebar Navigation

### Appearance Description

The main navigation container provides scrollable navigation with proper overflow handling and spacing between different navigation sections.

### Example Code

```html
<nav class="flex-1 px-3 space-y-0.5 overflow-y-auto overflow-x-hidden min-h-0">
  <!-- Dashboard Item -->
  <div class="mb-3">
    <div class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-900 bg-gray-50 rounded-md">
      <i class="fa fa-tachometer w-4 h-4"></i>
      <span class="font-medium text-sm">Dashboard</span>
    </div>
  </div>

  <!-- Navigation Sections -->
  <div class="flex items-center justify-between px-2.5 py-2 mb-2">
    <span class="text-xs font-medium text-gray-500 uppercase tracking-wide">Navigation</span>
    <div class="flex items-center gap-1">
      <button class="text-xs text-blue-600 hover:text-blue-700 focus:outline-none focus:ring-1 focus:ring-blue-500 rounded-sm px-1">
        Expand All
      </button>
      <span class="text-xs text-gray-400">|</span>
      <button class="text-xs text-blue-600 hover:text-blue-700 focus:outline-none focus:ring-1 focus:ring-blue-500 rounded-sm px-1">
        Collapse All
      </button>
    </div>
  </div>

  <!-- Navigation content -->
</nav>
```

### Usage Guidance

Use flex-1 for expandable navigation area. Include overflow-y-auto for scrollable content and overflow-x-hidden to prevent horizontal scrolling. Use space-y-0.5 for consistent spacing between navigation items. Add navigation controls for expand/collapse functionality.

---

## Sidebar Item

### Appearance Description

Sidebar items are vertically stacked links with icon and text. They use text-gray-900 for active and text-gray-600 for inactive states, with left padding and hover background to highlight. The entire item area should be clickable for better user experience.

### Example Code

```html
<!-- Active Item -->
<a href="/dashboard" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-900 bg-gray-50 rounded-md">
  <i class="fa fa-home w-4 h-4"></i>
  <span class="font-medium text-sm">Dashboard</span>
</a>

<!-- Inactive Item -->
<a href="/analytics/performance" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md">
  <i class="fa fa-bar-chart w-4 h-4"></i>
  <span class="text-sm">Performance</span>
</a>

<!-- Item with Badge -->
<a href="/analytics" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md">
  <i class="fa fa-bullseye w-4 h-4"></i>
  <span class="text-sm">Analytics</span>
  <span class="ml-auto bg-blue-100 text-blue-700 text-xs px-1.5 py-0.5 h-5 rounded-md">NEW</span>
</a>
```

### Usage Guidance

Use `<a>` tags as the container element to make the entire item clickable. Apply all styling classes directly to the `<a>` tag. Use consistent padding (px-2.5 py-1.5) for click targets. Highlight active items with bg-gray-50 and text-gray-900. Inactive items should have text-gray-600 with hover:text-gray-900 and hover:bg-gray-50. Use gap-2.5 for spacing between icon and text. Text should be text-sm size. Position badges with ml-auto. Remove default link underlines by ensuring proper Tailwind reset styles are applied.

---

## Sidebar Section

### Appearance Description

Sidebar sections group related navigation items with a header label in uppercase. Items within a section are stacked vertically with consistent spacing.

### Example Code

```html
<div class="space-y-0.5">
  <div class="px-2.5 py-1 text-xs font-medium text-gray-500 uppercase tracking-wide">ANALYTICS</div>
  <a href="/analytics/performance" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md">
    <i class="fa fa-bar-chart w-4 h-4"></i>
    <span class="text-sm">Performance</span>
  </a>
  <a href="/analytics/hotjar" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md">
    <i class="fa fa-bullseye w-4 h-4"></i>
    <span class="text-sm">Hotjar</span>
    <span class="ml-auto bg-blue-100 text-blue-700 text-xs px-1.5 py-0.5 h-5 rounded-md">NEW</span>
  </a>
</div>
```

### Usage Guidance

Use uppercase text-xs font-medium text-gray-500 for section headers with tracking-wide for letter spacing. Maintain consistent spacing between sections (mt-4) and items within sections (space-y-0.5). Badge indicators should be positioned with ml-auto.

---

## Sidebar Collapsible Section

### Appearance Description

Collapsible sections allow grouping of related navigation items with expand/collapse functionality. They include a clickable header with chevron icon and expandable content area.

### Example Code

```html
<div class="space-y-0.5">
  <div class="px-2.5 py-1 text-xs font-medium text-gray-500 uppercase tracking-wide">ANALYTICS</div>

  <!-- Collapsible Section -->
  <div>
    <button class="flex items-center justify-between w-full px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500"
            aria-expanded="false" aria-controls="analytics-submenu">
      <div class="flex items-center gap-2.5">
        <i class="fa fa-newspaper-o w-4 h-4"></i>
        <span class="text-sm">Analytics</span>
      </div>
      <i class="fa fa-caret-down w-4 h-4 transition-transform duration-200"></i>
    </button>

    <!-- Submenu (collapsed by default) -->
    <div id="analytics-submenu" class="ml-6 mt-1 space-y-0.5 transition-all duration-200 overflow-hidden max-h-0 opacity-0">
      <a href="/analytics/performance" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md">
        <div class="w-4 h-4 flex items-center justify-center">
          <div class="w-1.5 h-1.5 bg-gray-400 rounded-full"></div>
        </div>
        <span class="text-sm">Performance</span>
      </a>
      <a href="/analytics/hotjar" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md">
        <i class="fa fa-bullseye w-4 h-4"></i>
        <span class="text-sm">Hotjar</span>
        <span class="ml-auto bg-blue-100 text-blue-700 text-xs px-1.5 py-0.5 h-5 rounded-md">NEW</span>
      </a>
    </div>
  </div>

  <!-- Expanded Section -->
  <div>
    <button class="flex items-center justify-between w-full px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500"
            aria-expanded="true" aria-controls="support-submenu">
      <div class="flex items-center gap-2.5">
        <i class="fa fa-user w-4 h-4"></i>
        <span class="text-sm">Support</span>
      </div>
      <i class="fa fa-caret-down w-4 h-4 transition-transform duration-200 rotate-180"></i>
    </button>

    <!-- Submenu (expanded) -->
    <div id="support-submenu" class="ml-6 mt-1 space-y-0.5 transition-all duration-200 overflow-hidden max-h-96 opacity-100">
      <a href="/support/tickets" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md">
        <i class="fa fa-ticket w-4 h-4"></i>
        <span class="text-sm">Tickets</span>
        <span class="ml-auto bg-gray-200 text-gray-700 text-xs px-1.5 py-0.5 h-5 rounded-md">15</span>
      </a>
    </div>
  </div>
</div>
```

### Usage Guidance

Use aria-expanded and aria-controls for accessibility. Implement smooth transitions with transition-all duration-200. Use rotate-180 class for expanded chevron state. Nest submenus with ml-6 indentation. Use max-h-0 opacity-0 for collapsed state and max-h-96 opacity-100 for expanded state. Add focus:ring-2 focus:ring-blue-500 for keyboard navigation.

---

## Sidebar Footer

### Appearance Description

The sidebar footer contains utility navigation items like Settings and Logout, positioned at the bottom of the sidebar with a top border separator.

### Example Code

```html
<div class="px-3 py-3 border-t border-gray-200 space-y-0.5 shrink-0">
  <a href="/settings" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md">
    <i class="fa fa-cog w-4 h-4"></i>
    <span class="text-sm">Settings</span>
  </a>
  <a href="/logout" class="flex items-center gap-2.5 px-2.5 py-1.5 text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md">
    <i class="fa fa-sign-out w-4 h-4"></i>
    <span class="text-sm">Logout</span>
  </a>
</div>
```

### Usage Guidance

Use border-t border-gray-200 to separate footer from main navigation. Apply shrink-0 to prevent footer from shrinking. Maintain consistent spacing with space-y-0.5. Include common utility actions like Settings and Logout. Use same styling as regular sidebar items for consistency.

---

## Header Navigation

### Appearance Description

Header navigation includes search, language dropdown, notification icons, and user profile elements aligned horizontally with subtle spacing and interactive states. Uses Font Awesome 4.x icons for consistency with the project.

### Example Code

```html
<header class="bg-white border-b border-gray-200 h-16 flex items-center px-6">
  <div class="flex items-center justify-between w-full">
    <div class="flex items-center gap-4">
      <!-- Search Input -->
      <div class="relative">
        <i class="fa fa-search w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
        <input placeholder="Type to search" class="pl-9 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent w-72 text-sm h-9" type="text">
      </div>
      <!-- Language Dropdown -->
      <div class="relative">
        <button class="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" aria-haspopup="true" aria-expanded="false" id="language-button">
          <i class="fa fa-globe w-4 h-4"></i>
          <span>EN</span>
          <i class="fa fa-caret-down w-4 h-4"></i>
        </button>
        <!-- Dropdown menu (hidden by default) -->
        <div id="language-dropdown" class="absolute right-0 mt-2 w-48 bg-white border border-gray-200 rounded-md shadow-lg z-50 hidden" role="menu" aria-labelledby="language-button">
          <div class="py-1">
            <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100" role="menuitem">
              <span class="mr-3">🇺🇸</span>English (US)
            </button>
            <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100" role="menuitem">
              <span class="mr-3">🇪🇸</span>Español
            </button>
            <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100" role="menuitem">
              <span class="mr-3">🇫🇷</span>Français
            </button>
            <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100" role="menuitem">
              <span class="mr-3">🇩🇪</span>Deutsch
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- Right Side Actions -->
    <div class="flex items-center gap-3">
      <button class="h-8 w-8 flex items-center justify-center rounded-md hover:bg-gray-100">
        <i class="fa fa-comment w-4 h-4 text-gray-500"></i>
      </button>
      <button class="h-8 w-8 flex items-center justify-center rounded-md hover:bg-gray-100">
        <i class="fa fa-bell w-4 h-4 text-gray-500"></i>
      </button>
      <div class="w-8 h-8 bg-gray-400 rounded-full"></div>
    </div>
  </div>
</header>
```

### Usage Guidance

Position search input on the left with Font Awesome icon inside. Include language dropdown with proper ARIA attributes. Use ghost buttons for notification icons with consistent hover states. Keep consistent spacing (gap-3/gap-4) between elements. Use rounded-full for user avatar. Header should have fixed height (h-16) for consistency. Use Font Awesome 4.x icons (`fa fa-*` format) for consistency with the project.

---

## Dropdown Menu

### Appearance Description

Dropdown menus provide a clean interface for additional options with a trigger button and dropdown content. Modern dropdowns use proper ARIA attributes for accessibility and consistent styling patterns.

### Example Code

```html
<!-- Language/Selection Dropdown -->
<div class="relative">
  <button class="flex items-center gap-2 px-3 py-2 text-sm text-gray-600 hover:text-gray-900 hover:bg-gray-50 rounded-md border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" aria-haspopup="true" aria-expanded="false" id="dropdown-button">
    <i class="fa fa-globe w-4 h-4"></i>
    <span>EN</span>
    <i class="fa fa-caret-down w-4 h-4"></i>
  </button>
  <div id="dropdown-menu" class="absolute right-0 mt-2 w-48 bg-white border border-gray-200 rounded-md shadow-lg z-50 hidden" role="menu" aria-labelledby="dropdown-button">
    <div class="py-1">
      <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100" role="menuitem">
        <span class="mr-3">🇺🇸</span>English (US)
      </button>
      <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100" role="menuitem">
        <span class="mr-3">🇪🇸</span>Español
      </button>
      <button class="flex items-center w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100" role="menuitem">
        <span class="mr-3">🇫🇷</span>Français
      </button>
    </div>
  </div>
</div>

<!-- Simple Action Dropdown -->
<div class="relative">
  <button class="flex items-center text-sm px-3 py-1.5 rounded-sm hover:bg-gray-100">
    Sort by: Recent
    <i class="fa fa-caret-down w-4 h-4 ml-1"></i>
  </button>
  <div class="absolute right-0 mt-1 w-40 bg-white border border-gray-200 rounded-md shadow-lg py-1 z-10 hidden">
    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Recent</a>
    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Oldest</a>
    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Amount</a>
  </div>
</div>
```

### Usage Guidance

Use proper ARIA attributes (`aria-haspopup`, `aria-expanded`, `aria-labelledby`, `role="menu"`, `role="menuitem"`) for accessibility. Trigger elements should indicate dropdown functionality with chevron-down icon. Use `button` elements for interactive menu items and `a` elements for navigation links. Menu items should have consistent styling (px-4 py-2) and sufficient padding for clickable area. Use text-sm for all text elements. Add the 'hidden' class to hide the dropdown by default, and use JavaScript to toggle visibility. Include proper focus states with `focus:outline-none` and `focus:bg-gray-100`.

---

## Avatar

### Appearance Description

Avatars are circular elements with fixed size, used for user profiles or placeholders.

### Example Code

```html
<div class="w-8 h-8 bg-gray-400 rounded-full"></div>
```

### Usage Guidance

Use consistent sizing (w-8 h-8 for header, potentially larger elsewhere). For image avatars, add an img tag with object-cover to maintain aspect ratio:

```html
<div class="w-8 h-8 rounded-full overflow-hidden">
  <img src="avatar.jpg" alt="User avatar" class="w-full h-full object-cover" />
</div>
```

For placeholder avatars, use bg-gray-400 or similar neutral color.

---

## Icon

### Appearance Description

Icons are used throughout the UI, with different sizes depending on context, with text color classes to adapt color dynamically.

### Example Code

```html
<i class="fa fa-home w-4 h-4"></i>
<i class="fa fa-plus w-4 h-4 mr-2"></i>
<i class="fa fa-bell w-4 h-4 text-gray-500"></i>
```

### Usage Guidance

Use consistent icon system (SVG icons or icon font). Maintain standard sizes: w-5 h-5 for larger navigation elements, w-4 h-4 for most UI contexts including buttons. Add appropriate margin (mr-2) when used alongside text. Use text color classes (text-gray-500, text-blue-600) to control icon colors.

---

## Table

### Appearance Description

Tables provide structured data display with headers and rows.

### Example Code

```html
<table class="w-full border-collapse">
  <thead>
    <tr class="border-b border-gray-200">
      <th class="text-left py-3 px-4 text-sm font-medium text-gray-500">Invoice</th>
      <th class="text-left py-3 px-4 text-sm font-medium text-gray-500">Date</th>
      <th class="text-left py-3 px-4 text-sm font-medium text-gray-500">Amount</th>
      <th class="text-left py-3 px-4 text-sm font-medium text-gray-500">Status</th>
      <th class="w-12 py-3 px-4 text-sm font-medium text-gray-500"></th>
    </tr>
  </thead>
  <tbody>
    <tr class="border-b border-gray-200">
      <td class="py-3 px-4 text-sm font-medium">Standard Plan - Feb 2022</td>
      <td class="py-3 px-4 text-sm">07 February, 2022</td>
      <td class="py-3 px-4 text-sm">$59.00</td>
      <td class="py-3 px-4 text-sm">
        <div class="flex items-center gap-2">
          <div class="w-2 h-2 bg-green-500 rounded-full"></div>
          <span class="text-green-700">Complete</span>
        </div>
      </td>
      <td class="py-3 px-4 text-sm">
        <div class="relative">
          <button class="p-1 rounded-md hover:bg-gray-100">
            <i class="fa fa-ellipsis-h w-4 h-4"></i>
          </button>
          <!-- Dropdown menu (hidden by default) -->
          <div class="absolute right-0 mt-1 w-40 bg-white border border-gray-200 rounded-md shadow-lg py-1 z-10 hidden">
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Download</a>
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">View Details</a>
          </div>
        </div>
      </td>
    </tr>
    <!-- More rows -->
  </tbody>
</table>
```

### Usage Guidance

Use consistent padding (py-3 px-4) for all cells. Use text-sm for all text. Table headers should use font-medium text-gray-500. For status indicators, combine a colored dot (w-2 h-2 bg-green-500 rounded-full) with text. Add action buttons in the last column with appropriate dropdown menus.

---

## Input

### Appearance Description

Input fields have white backgrounds, subtle border with border-gray-300, rounded corners (rounded-md), and focus states with ring-2 ring-blue-500. Standard inputs include a label above the input.

### Example Code

```html
<div class="space-y-2">
  <label for="firstName" class="text-sm font-medium text-gray-900">
    First Name
  </label>
  <input
    id="firstName"
    type="text"
    placeholder="Enter your first name"
    class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
  />
</div>
```

### Usage Guidance

Always use labels with inputs for accessibility. Connect labels and inputs using matching 'for' and 'id' attributes. Use sufficient padding (px-3 py-2) for touch targets and typing comfort. Include placeholder text for guidance. Define appropriate width based on context (w-full for form fields). Use focus:outline-none focus:ring-2 focus:ring-blue-500 for accessible focus states. Use text-sm for consistent text size.

For search inputs that include an icon:

```html
<div class="relative">
  <i class="fa fa-search w-4 h-4 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
  <input
    type="text"
    placeholder="Type to search"
    class="pl-9 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent w-72 text-sm"
  />
</div>
```

---

## Button

### Appearance Description

Buttons come in various styles (primary, outline, ghost) and sizes. They can include icons and text.

### Example Code

```html
<!-- Primary Button -->
<button class="w-full bg-blue-600 hover:bg-blue-700 text-white text-sm h-9 px-4 rounded-md flex items-center justify-center">
  <i class="fa fa-plus w-4 h-4 mr-2"></i>
  Connect New Account
</button>

<!-- Outline Button -->
<button class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium">
  Cancel Subscription
</button>

<!-- Ghost Button -->
<button class="flex items-center text-sm px-3 py-1.5 rounded hover:bg-gray-100">
  Sort by: Recent <i class="fa fa-caret-down w-4 h-4 ml-1"></i>
</button>

<!-- Icon Button -->
<button class="h-8 w-8 flex items-center justify-center rounded-md hover:bg-gray-100">
  <i class="fa fa-comment w-4 h-4 text-gray-500"></i>
</button>
```

### Usage Guidance

Use primary buttons (bg-blue-600) for main actions. Use outline buttons for secondary actions. Use ghost buttons for tertiary actions or in compact spaces. Include icons where appropriate to enhance meaning. Size appropriately based on context and available space. Use text-sm for consistent text size.

## Tabs

### Appearance Description

Tabs organize content into different sections that can be switched between, with proper accessibility attributes for screen readers and keyboard navigation.

### Example Code

```html
<div class="h-10 items-center justify-center rounded-md p-1 text-muted-foreground grid w-full grid-cols-6 bg-gray-100">
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-xs px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-xs">Profile</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-xs px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-xs">Password</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-xs px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-xs">Team</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-xs px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-xs">Notification</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-xs px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-xs">Billing Details</button>
  <button class="inline-flex items-center justify-center whitespace-nowrap rounded-xs px-3 py-1.5 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-xs">Integration</button>
</div>

<!-- Tab Content (only the active one should be displayed) -->
<div class="space-y-6">
  <!-- Tab panels go here -->
</div>
```

### Usage Guidance

Use tabs for organizing related content that doesn't need to be visible simultaneously.

For styling: active tabs use `data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-xs`, while all tabs have consistent padding (`px-3 py-1.5`) and text size (`text-sm font-medium`).

Use the `data-[state=active]` attribute selectors for applying different styles to active tabs.

## Flash Message

### Appearance Description

Flash messages provide user feedback for actions with color-coded status indicators. They display below the header with left border styling, appropriate icons, and dismissible functionality. Messages include smooth transitions and proper ARIA attributes for accessibility.

### Example Code

```html
<!-- Success Message -->
<div class="transition-all duration-300 ease-in-out opacity-100 translate-y-0" role="alert" aria-live="polite">
  <div class="w-full bg-green-50 border-green-500 border-l-4 p-4 flex items-center justify-between">
    <div class="flex items-center space-x-3">
      <i class="fa fa-check-circle w-5 h-5 text-green-500"></i>
      <span class="text-green-800 font-medium">Profile updated successfully!</span>
    </div>
    <button class="text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 rounded-md" aria-label="Dismiss message">
      <i class="fa fa-times w-5 h-5"></i>
    </button>
  </div>
</div>

<!-- Error Message -->
<div class="transition-all duration-300 ease-in-out opacity-100 translate-y-0" role="alert" aria-live="assertive">
  <div class="w-full bg-red-50 border-red-500 border-l-4 p-4 flex items-center justify-between">
    <div class="flex items-center space-x-3">
      <i class="fa fa-times-circle w-5 h-5 text-red-500"></i>
      <span class="text-red-800 font-medium">Failed to save changes. Please try again.</span>
    </div>
    <button class="text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 rounded-md" aria-label="Dismiss message">
      <i class="fa fa-times w-5 h-5"></i>
    </button>
  </div>
</div>

<!-- Warning Message -->
<div class="transition-all duration-300 ease-in-out opacity-100 translate-y-0" role="alert" aria-live="polite">
  <div class="w-full bg-yellow-50 border-yellow-500 border-l-4 p-4 flex items-center justify-between">
    <div class="flex items-center space-x-3">
      <i class="fa fa-exclamation-triangle w-5 h-5 text-yellow-500"></i>
      <span class="text-yellow-800 font-medium">Your subscription will expire in 3 days.</span>
    </div>
    <button class="text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 rounded-md" aria-label="Dismiss message">
      <i class="fa fa-times w-5 h-5"></i>
    </button>
  </div>
</div>

<!-- Info Message -->
<div class="transition-all duration-300 ease-in-out opacity-100 translate-y-0" role="alert" aria-live="polite">
  <div class="w-full bg-blue-50 border-blue-500 border-l-4 p-4 flex items-center justify-between">
    <div class="flex items-center space-x-3">
      <i class="fa fa-info-circle w-5 h-5 text-blue-500"></i>
      <span class="text-blue-800 font-medium">New features have been added to your dashboard!</span>
    </div>
    <button class="text-gray-400 hover:text-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 rounded-md" aria-label="Dismiss message">
      <i class="fa fa-times w-5 h-5"></i>
    </button>
  </div>
</div>
```

### Usage Guidance

Flash messages appear below the header and provide immediate feedback for user actions. Use appropriate color schemes: green for success, red for errors, yellow for warnings, and blue for information. Include Font Awesome icons that match the message type. Error messages should use `aria-live="assertive"` while others use `aria-live="polite"`. The dismiss button should have proper ARIA labels for accessibility. Messages display with smooth transitions using `transition-all duration-300 ease-in-out` classes. Use `border-l-4` for the left accent border and consistent padding (p-4) for content spacing.

---

## Badge

### Appearance Description

Badges are small indicators used to highlight status, counts, or labels.

### Example Code

```html
<span class="ml-auto bg-blue-100 text-blue-700 text-xs px-1.5 py-0.5 h-5 rounded-md">
  NEW
</span>

<span class="ml-auto bg-gray-200 text-gray-700 text-xs px-1.5 py-0.5 h-5 rounded-md">
  15
</span>
```

### Usage Guidance

Use badges sparingly to highlight important information. Position with ml-auto when used in navigation items. Use appropriate color combinations for different states (blue for new features, gray for counts, etc.). Keep text concise and uppercase for emphasis. Use consistent sizing with px-1.5 py-0.5 h-5 and text-xs.
